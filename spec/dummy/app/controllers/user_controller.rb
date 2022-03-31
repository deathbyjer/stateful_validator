class UserController < ApplicationController
  sanitizer UserSanitizer, param_key: :user
  validator UserValidator

  def create
    populate do |input|
      self.model = User.new
      model.email = input.email
      model.save!
    end

    errors? ? render_error(errors) : render_ok(model)
  end

  def validations
    validate do 
      [
        [:email, :email_exists?, "required"],
        [:email, :email_is_email?, "invalid" ],
        [:email, :email_doesnt_already_exist?, "exists"]
      ]
    end

    populate do |input|
      self.model = User.new
      model.email = input.email
      model.save!
    end

    errors? ? render_error(errors) : render_ok(model)
  end

  def sanitizing
    validate do 
      [
        [:email, :sanitized_email_removes_extra_whitespace?, "sanitize"]
      ]
    end

    errors? ? render_error(errors) : render_ok
  end
end