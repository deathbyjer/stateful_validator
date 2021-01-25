class StatefulValidator::Validator

  def initialize(options = {})
    self.controller = options[:controller]
    set_current_user!
    
    self.input = options[:sanitizer]
    @model = options[:model]
  end

  private

  def model
    return @model if @model
    return nil unless controller
    return nil unless controller.respond_to?(:model)
    @model = self.controller.model
  end

  def set_current_user!
    return unless controller
    return unless controller.respond_to?(:current_user)
    self.current_user = controller.current_user
  end

  attr_accessor :input
  attr_accessor :controller
  attr_accessor :current_user

end