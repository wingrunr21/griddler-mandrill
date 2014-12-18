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
            headers: event[:headers],
            from: full_email([ event[:from_email], event[:from_name] ]),
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

      def recipients(field, event)
        Array.wrap(event[field]).map { |recipient| full_email(recipient) }
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
    end
  end
end
