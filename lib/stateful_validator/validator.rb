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
    return nil unless controller.respond_to?(:model, true)

    @model = controller.send(:model)
  end

  def input_for(name)
    return input if name == :default
    @input_for ||= {}
    return @input_for[name] if @input_for.key?(name)

    raise "Cannot look up additional sanitizers without a linked controller" unless controller

    list = controller.class._lookup_sanitizer(name: name)[:list]
    @input_for[name] = list ? controller.send(:merged_sanitizers, name: name) : controller.send(:sanitizer, name: name)
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