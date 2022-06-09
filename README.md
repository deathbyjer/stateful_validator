# StatefulValidator

Sometimes, we need more than ActiveRecord Validations. Business logic is not always stateless, and there are factors in the session that can affect what we are, or are not, allowed to do with a model. (Most frequently, a logged in user.)

Sanitization should be reliable and validations should be individually testable. 

StatefulValidator offers a graceful approach to these problems (albeit, with a bit more code.)
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stateful_validator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stateful_validator

## Usage

#### The Basic Controller

```ruby
class ExampleController < ActionController::Base
  sanitizer ExampleSanitizer, param_key: :example
  validator ExampleValidator

  def action
    validate do 
      [
        [:foo, :foo_matches_this_condition?, "is doesnt"],
        [:foo, :foo_is_certain_length_unless_admin, "short"],
      ]
    end

    populate do |input|
      self.model = BarModel.new
      self.model.foo = input.foo
      self.save!
    end

    errors? ? render(json: errors, status: 400) : render(json: model)
  end
end
```

So, there's a lot of things going on above. First, we set up the sanitizer and validator for the class, specifically assigning a key for the sanitizer to watch. (The sanitizer and validator will be expressed elsewhere)

Then we set up a validate block to run the validators. Displayed is a shortcut for convenience in running a group of validations.

Finally, the popuiate block wraps the save in a transaction, only running if there are no caught errors. 

The `populate` block will catch any errors sent by the ActiveRecord (so for very simple population, we do not necessarily need a validation block and can rely on the simple data-level validations there.) However, we must use the `save!` method to make sure that the Exceptions are raised as opposed to suppressing them only into the model's errors object with the `save` method.


#### A Sanitizer 

```ruby
class ExampleSanitizer < StatefulValidator::Sanitizer
  def foo
    @foo ||= params[:foo].to_s.strip
  end
end
```

We explicitly define and sanitize the incoming input, ensuring that it adheres to expected input. (We can memoize if we want to)

#### A Validator

```ruby
class ExampleValidator < StatefulValidator::Validator
  def foo_matches_this_condition?
    true # CONDITION HERE
  end

  def foo_is_certain_length_unless_admin
    return true if current_user&.admin?

    input.foo <= 30
  end

  private

  def current_user
    controller&.current_user
  end
end
```

(This method assumes a Devise-like setup, where the controller will have a `current_user` method.)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/stateful_validator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the StatefulValidator project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/stateful_validator/blob/master/CODE_OF_CONDUCT.md).
# stateful_validator
