class UserController < ApplicationController
  sanitizer UserSanitizer, param_key: :user
  sanitizer SpecialUserSanitizer, only: [:special_create], param_key: :user
  validator UserValidator

  def create
    populate do |input|
      self.model = User.new
      model.email = input.email
      model.save!
    end

    errors? ? render_error(errors) : render_ok(model)
  end

  def special_create
    
    populate do |input|
      self.model = User.new
      model.email = input.email
      model.save!
    end
    
    errors? ? render_error(errors) : render_ok(model)
  end

  validate_with PrependedValidator
  def prepended_create
    validate do |input|
      [
        [:random, :a_prepended_check?, "check-one"]
      ]
    end 

    errors? ? render_error(errors) : render_ok
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