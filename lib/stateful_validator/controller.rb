module StatefulValidator::Controller
  extend ActiveSupport::Concern

  module ClassMethods
    def sanitizer(klass = nil, options = {})
      return _sanitizers[nil] if klass.nil?
      return unless klass.ancestors.include?(StatefulValidator::Sanitizer)

      sanitizer = { klass: klass }
      sanitizer[:param_key] = options[:param_key] || klass.name.underscore.split("_")[0..-2].join("_").to_sym
      sanitizer[:ids] = options[:ids] if options[:ids]
      
      Array(options[:only] || [nil]).each {|action| _sanitizers[action ? action.to_sym : action] = sanitizer }
    end

    def validator(klass = nil, options = {})
      return _validators[nil] if klass.nil?
      return unless klass.ancestors.include?(StatefulValidator::Validator)

      validator = { klass: klass }
      Array(options[:only] || [nil]).each {|action| _validators[action ? action.to_sym : action] = validator }
    end

    def _lookup_sanitizer(action)
      _sanitizers[action.to_sym] || _sanitizers[nil]
    end

    def _lookup_validator(action)
      _validators[action.to_sym] || _validators[nil]
    end

    private

    def _sanitizers
      @_sanitizers ||= {}
    end

    def _validators
      @_validators ||= {}
    end
  end

  protected

  attr_accessor :model

  def sanitizer
    return @sanitizer if @sanitizer

    details = self.class._lookup_sanitizer params[:action]
    return nil unless details

    @sanitizer = details[:klass].new params[details[:param_key]].to_unsafe_h, controller: self
    @sanitizer.set_ids_from_params! params, details[:ids]
    @sanitizer
  end

  def validator
    return @validator if @validator

    details = self.class._lookup_validator params[:action]
    return nil unless details

    @validator = details[:klass].new(controller: self, sanitizer: sanitizer)
  end

  def errors
    @internal_errors ||= {}
  end

  def has_errors?
    !errors.empty?
  end

  def validate(&block)
    validations = block.call(sanitizer)
    return unless validations.is_a?(Array)

    auto_fill_validations validations 
  end

  def populate(&block)
    return unless errors.empty?

    ActiveRecord::Base.transaction do 
      begin
        block.call(sanitizer)
      rescue StatefulValidator::ValidationError => e
        errors.merge! e.errors
      rescue ActiveRecord::RecordInvalid => e
        errors.merge! e.record.errors
      end

      raise ActiveRecord::Rollback unless errors.empty?
    end
  end

  private

  # This will fill the validations that is an array of arrays, where the internal array has the
  # following format:
  #
  # [:error_type, :validation, "error string"]
  #
  # So an example may be
  #
  # [:price_must_not_be_zero, "invalid price", :price]
  def auto_fill_validations(validations)
    validations.each do |validation|
      next unless validation.is_a?(Array)
      next unless validation.count == 3
      error_key, error, the_validation = validation[0], validation[2], validation[1]

      next unless the_validation.is_a?(Proc) || validator.respond_to?(the_validation) 
      error_key = [error_key] unless error_key.is_a?(Array)
      validated = the_validation.is_a?(Proc) ? the_validation.call : validator.send(the_validation)
      error_key.each {|key| errors[key] = error unless errors[key] } unless validated
    end
  end

end
