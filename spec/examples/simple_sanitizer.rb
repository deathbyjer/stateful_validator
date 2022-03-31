class SimpleSanitizer < StatefulValidator::Sanitizer
  def number
    params[:number].to_i
  end

  def string
    params[:string].to_s
  end

  def sanitized_string
    self.class.sanitize params[:string]
  end
end