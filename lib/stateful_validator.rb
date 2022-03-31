
module StatefulValidator
  require 'stateful_validator/version'
  require 'stateful_validator/errors'
  require 'stateful_validator/utilities'
  require 'stateful_validator/sanitizer'
  require 'stateful_validator/validator'
  require 'stateful_validator/validation_error'
end

if defined?(ActiveSupport)
  require "stateful_validator/controller"

  ActiveSupport.on_load(:action_controller) do
    include StatefulValidator::Controller
  end
end