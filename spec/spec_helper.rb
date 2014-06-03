require 'griddler/testing'
require 'griddler/mandrill'
require 'action_dispatch'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.order = 'random'
  config.include Griddler::Testing
end

RSpec::Matchers.define :be_normalized_to do |expected|
  failure_message do |actual|
    message = ""
    expected.each do |k, v|
      message << "expected :#{k} to be normalized to #{expected[k].inspect}, "\
      "but received #{actual[k].inspect}\n" unless actual[k] == expected[k]
    end
    message
  end

  description do
    "be normalized to #{expected}"
  end

  match do |actual|
    expected.each do |k, v|
      case v
      when Regexp then expect(actual[k]).to match v
      else expect(actual[k]).to eq v
      end
    end
  end
end
