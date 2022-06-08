class PostValidator < StatefulValidator::Validator

  def title_is_allowed_to_have_numbers?
    return true if current_user.admin?

    !(input.title =~ /\d/)
  end

  def body_is_not_too_long?
    return input.body.length < 200 if current_user.admin?

    input.body.length < 100
  end

  private

  def current_user
    controller.current_user || User.new
  end
end