require 'active_support/concern'

module StatefulValidator::Controller::Validate
  extend ActiveSupport::Concern

  module ClassMethods
    def validator(klass = nil, options = {})
      return _validators[nil] if klass.nil?

      options = { action: options[:only] }.merge(options)

      validator = __prepare_validator klass, options
      StatefulValidator::Utilities.assign_to_lookup _validators, options, validator
    end

    def named_validator(name, klass = nil, options = {})
      validator klass, options.merge(name: name)
    end

    def named_validators(name, klass = nil, options = {})
      validator klass, options.merge(name: name, list: true)
    end

    def action_validator(klass, options = {})
      klass = _lookup_validator(name: klass) unless klass.is_a?(Module)

      @action_validator = klass ? __prepare_validator(klass, options) : nil
    end
    
    alias_method :validate_with, :action_validator

    def _lookup_validator(opts)
      StatefulValidator::Utilities.lookup _validators, opts
    end

    protected
    
    def _validators
      @_validators ||= { actions: {}, names: {} }
    end

    def __prepare_validator(klass, options)
      raise StatefulValidator::Errors::IllegalValidator unless is_validator?(klass)

      list_klass = defined?(klass::List) ? klass::List : nil
      list_klass = nil unless is_validator?(list_klass)
      list_klass ||= klass

      {
        klass: klass,
        list_klass: list_klass,
        list: options[:list] ? true : false
      }.compact
    end

    def is_validator?(klass)
      klass&.ancestors&.include?(StatefulValidator::Validator)
    end
  end

  def validator(opts = {})
    validators(opts)[opts[:index].to_i]
  end

  def validators(opts = {})
    opts = opts.merge(action: params[:action].to_sym)
    @validators ||= { default: [], names: {} }

    # Lookup a generated sanitizer
    found_validators = StatefulValidator::Utilities.lookup @validators, opts.merge(no_default: true)
    return found_validators[0...-1] if found_validators.present?

    details = self.class._lookup_validator opts
    validators = sanitizers(opts).map do |sanitizer|
      details[:klass].new(controller: self, sanitizer: sanitizer)
    end

    validators << details[:list_klass]&.new(controller: self, sanitizer: merged_sanitizers(opts))

    StatefulValidator::Utilities.assign_to_lookup @validators, opts, validators
    validators[0...-1]
  end

  def merged_validator(opts)
    opts = opts.merge(action: params[:action])
    validators(opts)
    
    found_validators = StatefulValidator::Utilities.lookup @validators, opts
    found_validators.last
  end

  def validate(opts = {}, alt_opts = {}, &block)
    opts = clean_populate_block_options opts, alt_opts
    is_list = self.class._lookup_sanitizer(opts)[:list] && !alt_opts[:for_each]
    
    selected_sanitizer = is_list ? merged_sanitizers(opts) : sanitizer(opts)
    selected_validator = is_list ? merged_validator(opts) : validator(opts)
    
    opts.merge!(merged_list: true) if is_list

    setup_validation_context(opts) do 
      validations = block.call(selected_sanitizer, selected_validator)
      auto_fill_validations(validations, opts) if validations.is_a?(Array)
    end
  end

  def validate_for_each(opts = {}, alt_opts = {}, &block)
    opts = clean_populate_block_options opts, alt_opts

    sanitizer_list = sanitizers(opts)

    if sanitizer_list.empty?
      errors(opts)[:error] = 'required' if opts[:required]
      return
    end

    sanitizer_list.each_index do |index|
      validate(opts.merge(index: index), {for_each: true}, &block)
    end
  end
  

  def errors(opts = {})
    opts = clean_populate_block_options opts
    is_list = self.class._lookup_sanitizer(opts)&.fetch(:list, false)

    local_errors = StatefulValidator::Utilities.get_or_set all_errors, opts, []
    opts[:index] = sanitizers(opts).count if opts[:index] == :all

    local_errors[opts[:index].to_i] ||= {}

    return local_errors[opts[:index].to_i] if opts.key?(:index)
    return local_errors if is_list

    local_errors[opts[:index].to_i]
  end

  def all_errors
    @all_errors ||= { default: [], names: {}}
  end

  def errors?
    # Check default area
    return true if all_errors[:default].any?(&:any?)
    return false if all_errors[:names].values.empty?

    all_errors[:names].values.any? do |errors|
      errors.any? {|error| error&.any? }
    end
  end

  def add_error(key, error) 
    within_validation_context do |opts|
      # If we are working off a merged list
      if opts&.fetch(:merged_list, nil)
        sanitizers(opts).each_index do |index| 
          attach_error_to_list(key: key, error: error, index: index) 
        end

      elsif opts
        attach_error_to_list(key: key, error: error)
      else
        errors[key] = error
      end
    end
  end

  alias has_errors? errors?

  protected

  def attach_error_to_list(key:, index: nil, error:)
    within_validation_context do |opts|
      error_list = errors(index.nil? ? {index: 0}.merge(opts) : opts.merge(index: index))
      error_list[key] = error unless error_list[key]
    end
  end

  # Validation context
  def setup_validation_context(opts, &block)
    @__validation_context = opts
    block.call
    @__validation_context = nil
  end

  def within_validation_context(&block)
    block.call @__validation_context
  end
  

  # This will fill the validations that is an array of arrays, where the internal array has the
  # following format:
  #
  # [:error_type, :validation, "error string"]
  #
  # So an example may be
  #
  # [:price_must_not_be_zero, "invalid price", :price]
  def auto_fill_validations(validations, opts = {})
    validations.each do |validation|
      next unless validation.is_a?(Array)
      next unless validation.count == 3

      error_key, the_validation, error = validation[0..2]
      the_validator = opts[:merged_list] ? merged_validator(opts) : validator(opts)

      next unless the_validation.is_a?(Proc) || the_validator.respond_to?(the_validation)

      error_key = [error_key] unless error_key.is_a?(Array)
      validated = the_validation.is_a?(Proc) ? the_validation.call : the_validator.send(the_validation)
      error_key.each {|key| add_error(key, error) } unless validated
    end
  end

end