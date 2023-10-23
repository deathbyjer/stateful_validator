class NamedController < ApplicationController
  named_sanitizer :user, UserSanitizer, param_key: :user
  named_validator :user, UserValidator

  named_sanitizer :post, PostSanitizer, param_key: :post
  named_validator :post, PostValidator
  named_sanitizer :global_post, PostSanitizer, param_key: false
  named_validator :global_post, PostValidator


  named_sanitizers :posts, PostSanitizer, param_key: :posts
  named_validators :posts, PostValidator

  def create_user

  end

  def create_post
    validate(:post) do
      [
        [:title, :title_is_allowed_to_have_numbers?, "no numbers"],
        [:body, :body_is_not_too_long?, "too long"]
      ]
    end

    populate(:post) do |input|
      self.model = Post.new
      model.title = input.title
      model.body = input.body
      model.user = input.user || current_user
      model.save!
    end

    errors? ? render_error(errors(:post)) : render_ok(model)
  end

  def create_global_post
    validate(:global_post) do
      [
        [:title, :title_is_allowed_to_have_numbers?, "no numbers"],
        [:body, :body_is_not_too_long?, "too long"]
      ]
    end

    populate(:global_post) do |input|
      self.model = Post.new
      model.title = input.title
      model.body = input.body
      model.user = input.user || current_user
      model.save!
    end

    errors? ? render_error(errors(:global_post)) : render_ok(model)
  end

  def create_posts
    validate_for_each(:posts) do
      [
        [:title, :title_is_allowed_to_have_numbers?, "no numbers"],
        [:body, :body_is_not_too_long?, "too long"]
      ]
    end

    @models = []
    populate_for_each(:posts) do |input|
      @models << (model = Post.new)
      model.title = input.title
      model.body = input.body
      model.user = input.user || current_user
      model.save!
    end

    errors? ? render_error(errors(:posts)) : render_ok(@models)
  end

  def check_post_list
    @models = []

    populate_for_all(:posts) do |inputs|
      inputs.each do |input| 
        @models << ( model = Post.new)
        model.title = input.title
        model.save!
      end
    end

    errors? ? render_error(errors(:posts)) : render_ok(@models)
  end
end