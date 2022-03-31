class StatefulValidator::Controller::SanitizerListWrapper
  def initialize(sanitizers, klass)
    @sanitizers = sanitizers
    @test_sanitizer = klass.new({})
  end

  def send(method_name, *args)
    sanitizer_method = find_method_in_sanitizers method_name

    if sanitizer_method
      @sanitizers.map {|s| s.send(sanitizer_method, *args) }
    else
      super
    end
  end

  def method_missing(method_name, *args)
    sanitizer_method = find_method_in_sanitizers method_name

    if sanitizer_method
      @sanitizers.map { |s| s.send(sanitizer_method, *args) }
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    find_method_in_sanitizers(method_name) ? true : super
  end

  def respond_to?(method_name)
    find_method_in_sanitizers(method_name) ? true : super
  end

  private

  def find_method_in_sanitizers(method_name)
    return method_name if @test_sanitizer.respond_to?(method_name)

    # we can accept plural versions in ActiveSupport
    if defined?(ActiveSupport)
      method_name = method_name.to_s.singularize.to_sym
      return method_name if @test_sanitizer.respond_to?(method_name)
    end

    false
  end
end