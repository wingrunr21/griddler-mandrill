module Griddler
  module Mandrill
    class Adapter
      def initialize(params)
        @params = params
      end

      def self.allow_spf_none?
        @allow_spf_none || false
      end

      def allow_spf_none?
        self.class.allow_spf_none?
      end

      def self.allow_spf_none=(allow_spf_none)
        @allow_spf_none = allow_spf_none
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def event_passes_spf?(event)
        event[:spf].present? &&
          ((event[:spf][:result] == 'pass' || event[:spf][:result] == 'neutral') ||
          (allow_spf_none? && event[:spf][:result] == 'none'))
      end

      def normalize_params
        events.select do |event|
          event_passes_spf?(event)

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
            email: event[:email], # the email address where Mandrill received the message
            spam_report: event[:spam_report]
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
        files(event, :attachments) + files(event, :images)
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
