
module StatefulValidator
  require "stateful_validator/version"
  require "stateful_validator/controller"
  require "stateful_validator/sanitizer"
  require "stateful_validator/validator"
  require "stateful_validator/validation_error"
end

ActiveSupport.on_load(:action_controller) do
  include StatefulValidator::Controller
end if defined?(ActiveSupport)
