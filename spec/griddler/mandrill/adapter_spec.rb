require 'spec_helper'

describe Griddler::Mandrill::Adapter do
  it 'registers itself with griddler' do
    expect(Griddler.adapter_registry[:mandrill]).to eq Griddler::Mandrill::Adapter
  end
end

describe Griddler::Mandrill::Adapter, '.normalize_params' do
  it 'normalizes parameters' do
    Griddler::Mandrill::Adapter.normalize_params(default_params).each do |params|
      expect(params).to be_normalized_to(params_hash_normalized)
    end
  end

  it 'does not process events that are not inbound' do
    params = mixed_event_params

    normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)

    expect(JSON.parse(params[:mandrill_events]).size).to eq(4)
    expect(normalized_params.size).to eq(2)
    normalized_params.each do |params|
      expect(params).to be_normalized_to(params_hash_normalized)
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

  it 'works with non-base64 encoded files' do
    params = params_with_csv_attachment

    normalized_params = Griddler::Mandrill::Adapter.normalize_params(params)

    file, = *normalized_params[0][:attachments]

    expect(file.original_filename).to eq('file.csv')
    expect(file.size).to eq(upload_3_params[:length])
  end

  it 'works with filenames containing slashes' do
    params = params_with_attachments_with_slashes

    adapter = Griddler::Mandrill::Adapter.new(params)
    expect{adapter.normalize_params}.to_not raise_error
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

  describe 'when the email text part is nil' do
    before do
      @params = params_hash
      @params.first[:msg][:text] = nil
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

  describe 'when the email html part is nil' do
    before do
      @params = params_hash
      @params.first[:msg][:html] = nil
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

  def mixed_event_params
    mandrill_events ((params_hash * 2) + (mixed_params_hash*2)).to_json
  end

  def mandrill_events(json)
    { mandrill_events: json }
  end

  def mixed_params_hash
    [{
      type: 'blacklist',
      action: 'change',
      reject: {
        reason: 'hard-bounce',
        detail: ' smtp;550 Requested action not taken: mailbox unavailable\n',
        last_event_at: '2014-11-03 04:56:18',
        email: 'herman@example.com',
        created_at: '2014-08-07 04:59:20',
        expires_at: '2014-11-24 04:56:18',
        expired: false,
        subaccount: nil,
        sender: nil
      },
      ts: 1414990578
    }]
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
          bcc: [['hidden@example.mandrillapp.com', 'Roger']],
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

  def params_hash_normalized
    {
      to: ['The Token <token@reply.example.com>'],
      cc: ['Emily <emily@example.mandrillapp.com>',
           'Joey <joey@example.mandrillapp.com>'],
      bcc: ['Roger <hidden@example.mandrillapp.com>'],
      from: 'Hernan Example <hernan@example.com>',
      subject: 'hello',
      text: %r{Dear bob},
      html: %r{<p>Dear bob</p>},
      raw_body: %r{raw}
    }
  end

  def params_with_attachments
    params = params_hash
    params[0][:msg][:attachments] = {
      'photo1.jpg' => upload_1_params,
      'photo2.jpg' => upload_2_params
    }
    mandrill_events params.to_json
  end

  def params_with_attachments_with_slashes
    params = params_hash
    params[0][:msg][:attachments] = {
      '=?UTF-8?B?0JrQvtC/0LjRjyB0ZW5kZXJfMTJfcm9zdGEueGxz?=' => upload_4_params,
      '=?UTF-8?B?0JrQvtC\0LjRjyB0ZW5kZXJfMTJfcm9zdGEueGxz?=' => upload_5_params
    }
    mandrill_events params.to_json
  end

  def params_with_csv_attachment
    params = params_hash
    params[0][:msg][:attachments] = {
      'file.csv' => upload_3_params
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
        length: size,
        base64: true
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
        length: size,
        base64: true
      }
    end
  end

  def upload_3_params
    @upload_2_params ||= begin
      content = 'Some | csv | file | here'
      {
        name: 'file.csv',
        content: content,
        type: 'text/plain',
        length: content.length,
        base64: false
      }
    end
  end

  def upload_4_params
    @upload_4_params ||= begin
      content = 'Some | csv | file | here'
      {
        name: '=?UTF-8?B?0JrQvtC/0LjRjyB0ZW5kZXJfMTJfcm9zdGEueGxz?=',
        content: content,
        type: 'image/jpeg',
        type: 'text/plain',
        base64: false
      }
    end
  end

  def upload_5_params
    @upload_5_params ||= begin
      content = 'Some | csv | file | here'
      {
        name: '=?UTF-8?B?0JrQvtC\0LjRjyB0ZW5kZXJfMTJfcm9zdGEueGxz?=',
        content: content,
        type: 'text/plain',
        length: content.length,
        base64: false
      }
    end
  end
end
