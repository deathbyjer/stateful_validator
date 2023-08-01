class PrependedSanitizer < StatefulValidator::Sanitizer
  def email
    "prepend@bar.com"
  end

  def sanitized_email
    self.class.saniize input.email
  end
end