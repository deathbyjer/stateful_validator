class PrependedValidator < StatefulValidator::Validator

  def a_prepended_check?
    true
  end

  private

  def current_user
    controller.current_user || User.new
  end
end