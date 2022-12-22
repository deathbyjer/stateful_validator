class SpecialUserSanitizer < StatefulValidator::Sanitizer
  def email
    "foo@bar.com"
  end

  def sanitized_email
    self.class.saniize input.email
  end
end