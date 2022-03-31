class UserSanitizer < StatefulValidator::Sanitizer
  def email
    params[:email].to_s
  end

  def sanitized_email
    self.class.saniize params[:email]
  end
end