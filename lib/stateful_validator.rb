require "stateful_validator/version"
require "stateful_validator/controller"


module StatefulValidator
end

ActiveSupport.on_load(:action_controller) do
  include StatefulValidator::Controller
end if defined?(ActiveSupport)
