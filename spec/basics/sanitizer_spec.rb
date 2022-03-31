#require './spec_helper'
require File.dirname(__FILE__) + "/../examples/simple_sanitizer"

RSpec.describe StatefulValidator::Sanitizer do
  let(:sanitizer) { SimpleSanitizer.new({number: 1, string: "foo  "}) }

  it 'can load parameters' do
    expect(sanitizer.number).to be(1)
  end

  it 'loads the html sanitization methods' do
    expect(sanitizer.sanitized_string).to eq("foo")
  end
end