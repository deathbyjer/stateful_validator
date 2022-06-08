class PostSanitizer < StatefulValidator::Sanitizer

  def title
    self.class.sanitize params[:title]
  end

  def body
    self.class.sanitize params[:body]
  end

  def user
    @user ||= User.find_by params[:user_id]
  end
end