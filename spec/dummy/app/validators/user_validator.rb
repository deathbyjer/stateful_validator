class UserValidator < StatefulValidator::Validator
  def email_exists?
    input.has?(:email)
  end

  def email_removes_extra_whitespace?
    input.email.length == input.email.strip.length
  end

  def sanitized_email_removes_extra_whitespace?
    input.sanitized_email.length == input.sanitized_email.strip.length
  end

  def email_is_email?
    input.email =~ /^.+@.+\..+$/
  end

  def email_doesnt_already_exist?
    !User.where(email: input.email).exists?
  end
end