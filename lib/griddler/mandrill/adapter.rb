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
        events.select do |event|
          event[:spf].present? && (event[:spf][:result] == 'pass' || event[:spf][:result] == 'neutral')
        end.map do |event|
          {
            to: recipients(:to, event),
            cc: recipients(:cc, event),
            bcc: resolve_bcc(event),
            headers: event[:headers],
            from: full_email([ event[:from_email], event[:from_name] ]),
            subject: event[:subject],
            text: event[:text] || '',
            html: event[:html] || '',
            raw_body: event[:raw_msg],
            attachments: attachment_files(event),
            email: event[:email] # the email address where Mandrill received the message
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

      def recipients(field, event)
        Array.wrap(event[field]).map { |recipient| full_email(recipient) }
      end

      def resolve_bcc(event)
        email = event[:email]
        to_and_cc = (event[:to].to_a + event[:cc].to_a).compact.map(&:first)
        to_and_cc.include?(email) ? [] : [full_email([email, email.split("@")[0]])]
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
        files(event, :attachments) + files(event, :images) + inline_ics_files(event)
      end

      def inline_ics_files(event)
        mail = Mail.new(event[:raw_msg])

        ics_parts = mail.parts.select do |part|
          !part.attachment? && part.mime_type =~ /text\/calendar/
        end

        ics_parts.map do |part|
          file = {
            content: part.body.to_s,
            name: part.filename || "invite.ics"
          }

          ActionDispatch::Http::UploadedFile.new({
            filename: file[:name],
            type: part.mime_type,
            tempfile: create_tempfile(file)
          })
        end
      end

      def files(event, key)
        files = event[key] || Hash.new

        files.map do |key, file|
          file[:base64] = true if !file.has_key?(:base64)

          ActionDispatch::Http::UploadedFile.new({
            filename: file[:name],
            type: file[:type],
            tempfile: create_tempfile(file)
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
    end
  end
end
