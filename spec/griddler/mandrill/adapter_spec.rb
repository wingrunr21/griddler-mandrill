require 'spec_helper'

describe Griddler::Mandrill::Adapter do
  it 'registers itself with griddler' do
    expect(Griddler.adapter_registry[:mandrill]).to eq Griddler::Mandrill::Adapter
  end
end

describe Griddler::Mandrill::Adapter, '.normalize_params' do
  it 'normalizes parameters' do
    Griddler::Mandrill::Adapter.normalize_params(default_params).each do |params|
      expect(params).to be_normalized_to({
        to: ['The Token <token@reply.example.com>'],
        cc: ['Emily <emily@example.mandrillapp.com>',
             'Joey <joey@example.mandrillapp.com>'],
        from: 'Hernan Example <hernan@example.com>',
        subject: 'hello',
        text: %r{Dear bob},
        html: %r{<p>Dear bob</p>},
        raw_body: %r{raw}
      })
    end
  end

  it 'passes the received array of files' do
    params = params_with_attachments

    normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)

    first, second = *normalized_params[0][:attachments]

    expect(first.original_filename).to eq('photo1.jpg')
    expect(first.size).to eq(upload_1_params[:length])

    expect(second.original_filename).to eq('photo2.jpg')
    expect(second.size).to eq(upload_2_params[:length])
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)

    expect(normalized_params[0][:attachments]).to be_empty
  end

  describe 'when the email has no text part' do
    before do
      @params = params_hash
      @params.first[:msg].delete(:text)
    end

    it 'sets :text to an empty string' do
      params = default_params(@params)
      normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)
      normalized_params.each do |p|
        expect(p[:text]).to eq ''
      end
    end
  end

  describe 'when the email has no html part' do
    before do
      @params = params_hash
      @params.first[:msg].delete(:html)
    end

    it 'sets :html to an empty string' do
      params = default_params(@params)
      normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)
      normalized_params.each do |p|
        expect(p[:html]).to eq ''
      end
    end
  end

  describe 'when the email has no CC recipients' do
    before do
      @params = params_hash
      @params.first[:msg][:cc] = nil
    end

    it 'should return an empty cc array' do
      params = default_params(@params)
      normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)
      normalized_params.each do |p|
        expect(p[:cc]).to eq []
      end
    end
  end

  def default_params(params = params_hash)
    mandrill_events (params * 2).to_json
  end

  def mandrill_events(json)
    { mandrill_events: json }
  end

  def params_hash
    [{
      event: 'inbound',
      ts: 1364601140,
      msg:
        {
          raw_msg: 'raw',
          headers: {},
          text: text_body,
          html: text_html,
          from_email: 'hernan@example.com',
          from_name: 'Hernan Example',
          to: [['token@reply.example.com', 'The Token']],
          cc: [['emily@example.mandrillapp.com', 'Emily'],
               ['joey@example.mandrillapp.com', 'Joey']],
          subject: "hello",
          spam_report: {
            score: -0.8,
            matched_rules: '...'
            },
          dkim: { signed: true, valid: true },
          spf: { result: 'pass', detail: 'sender SPF authorized' },
          email: 'token@reply.example.com',
          tags: [],
          sender: nil
        }
    }]
  end

  def params_with_attachments
    params = params_hash
    params[0][:msg][:attachments] = {
      'photo1.jpg' => upload_1_params,
      'photo2.jpg' => upload_2_params
    }
    mandrill_events params.to_json
  end

  def text_body
    <<-EOS.strip_heredoc.strip
      Dear bob

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def text_html
    <<-EOS.strip_heredoc.strip
      <p>Dear bob</p>

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def upload_1_params
    @upload_1_params ||= begin
      file = upload_1
      size = file.size
      {
        name: 'photo1.jpg',
        content: Base64.encode64(file.read),
        type: 'image/jpeg',
        length: size
      }
    end
  end

  def upload_2_params
    @upload_2_params ||= begin
      file = upload_2
      size = file.size
      {
        name: 'photo2.jpg',
        content: Base64.encode64(file.read),
        type: 'image/jpeg',
        length: size
      }
    end
  end
end
