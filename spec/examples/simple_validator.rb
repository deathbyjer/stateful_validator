class SimpleValidator < StatefulValidator::Validator
  def is_number_zero?
    input.number == 0
  end

  def is_number_one?
    input.number == 1
  end

  def string_is_foo?
    input.string == "foo"
  end

  def sanitized_string_is_foo?
    input.sanitized_string == "foo"
  end
end