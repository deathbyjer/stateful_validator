require File.dirname(__FILE__) + "/../examples/simple_sanitizer"
require File.dirname(__FILE__) + "/../examples/simple_validator"

RSpec.describe StatefulValidator::Validator do 
  context 'basics' do
    let(:sanitizer) { SimpleSanitizer.new(number: 1, string: "foo") }
    let(:validator) { SimpleValidator.new(sanitizer: sanitizer) }

    it 'generates a validator' do
      expect(validator).to be_a(StatefulValidator::Validator)
    end

    it 'performs validations' do
      expect(validator.is_number_one?).to be_truthy
      expect(validator.sanitized_string_is_foo?).to be_truthy
    end

    it 'fails when validation fails' do
      expect(validator.is_number_zero?).to be_falsey
    end
  end
end