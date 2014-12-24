module Griddler
  module Mandrill
    class Adapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        events.map do |event|
          {
            to: recipients(:to, event),
            cc: recipients(:cc, event),
            bcc: recipients(:bcc, event),
            from: from(event),
            subject: event[:subject],
            text: event[:text] || '',
            html: event[:html] || '',
            raw_body: event[:raw_msg],
            attachments: attachment_files(event)
          }
        end
      end

      private

      attr_reader :params

      def events
        @events ||= ActiveSupport::JSON.decode(params[:mandrill_events]).map { |event|
          event['msg'].with_indifferent_access if event['event'] == 'inbound'
        }.compact
      end

      def from(event)
        from_contact = full_email([ event[:from_email], event[:from_name] ])
        # Attempt to get from contact from raw headers as a last resort
        from_contact = header_contacts(:from, event).first if from_contact.nil?
        from_contact
      end

      def recipients(field, event)
        rcpts = Array.wrap(event[field]).map { |recipient| full_email(recipient) }
        # Attempt to get recipients from raw headers as a last resort
        rcpts = header_contacts(field, event) if rcpts.empty?
        rcpts
      end

      def header_contacts(field, event)
        case field
        when :from
          header_prefix = 'From:'
        when :to
          header_prefix = 'To:'
        when :cc
          header_prefix = 'Cc:'
        when :bcc
          header_prefix = 'Bcc:'
        end

        if event[:raw_msg].present? && matches = event[:raw_msg].match(/\n#{header_prefix}.+\n/i)
          emails = matches.to_s.gsub!(/\n|#{header_prefix}/i,'')

          return Array.wrap(emails.split(',').map { |email_info|
            email = email_info.scan(email_regex).first
            email_info.gsub!(/#{Regexp.escape(email)}|<|>/i, '') #remove the email address
            name = email_info.strip
            name = nil if name.empty? #name is whatever is left
            full_email([ email, name ])
          })
        end

        []
      end

      def full_email(contact_info)
        email = contact_info[0]
        if contact_info[1]
          "#{contact_info[1]} <#{email}>"
        else
          email
        end
      end

      def attachment_files(event)
        attachments = event[:attachments] || Array.new
        attachments.map do |key, attachment|
          ActionDispatch::Http::UploadedFile.new({
            filename: attachment[:name],
            type: attachment[:type],
            tempfile: create_tempfile(attachment)
          })
        end
      end

      def create_tempfile(attachment)
        filename = attachment[:name].gsub(/\/|\\/, '_')
        tempfile = Tempfile.new(filename, Dir::tmpdir, encoding: 'ascii-8bit')
        content = attachment[:content]
        content = Base64.decode64(content) if attachment[:base64]
        tempfile.write(content)
        tempfile.rewind
        tempfile
      end

      # http://www.regular-expressions.info/email.html
      def email_regex
        /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
      end
    end
  end
end
