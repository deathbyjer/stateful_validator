module StatefulValidator::Controller
  extend ActiveSupport::Concern

  class << self
    def sanitizer(instance, action)
      instance.class.send(:_stateful_sanitizers)[action.to_sym] || instance.class.send(:_stateful_sanitizers)[nil]
    end

    def validator(instance, action)
      instance.class.send(:_stateful_validators)[action.to_sym] || instance.class.send(:_stateful_validators)[nil]
    end



    # This will fill the validations that is an array of arrays, where the internal array has the
    # following format:
    #
    # [:error_type, :validation, "error string"]
    #
    # So an example may be
    #
    # [:price_must_not_be_zero, "invalid price", :price]
    def auto_fill_validations(instance, validations)
      validations.each do |validation|
        next unless validation.is_a?(Array)
        next unless validation.count == 3

        validator = instance.validator
        error_key, error, the_validation = Array.wrap(validation[0]), validation[2], validation[1]
        next unless the_validation.is_a?(Proc) || validator.respond_to?(the_validation) 

        validated = if the_validation.is_a?(Proc) 
          the_validation.call
        else 
          validator.send(the_validation)
        end

        error_key.each do |key| 
          errors[key] = error unless errors[key] 
        end unless validator
      end
    end
  end


  module ClassMethods
    def sanitizer(klass = nil, options = {})
      return _stateful_sanitizers[nil] if klass.nil?
      return unless klass.ancestors.include?(ApplicationSanitizer)

      sanitizer = { 
        klass: klass, 
        ids: options[:ids],
        param_key: options[:param_key] || klass.name.underscore.split("_")[0..-2].join("_").to_sym
      }.compact
      
      Array.wrap(options[:only]).each do |action| 
        _stateful_sanitizers[action&.to_sym] = sanitizer 
      end
    end

    def validator(klass = nil, options = {})
      return _stateful_validators[nil] if klass.nil?
      return unless klass.ancestors.include?(ApplicationValidator)

      validator = { klass: klass }
      Array.wrap(options[:only]).each do |action| 
        _stateful_validators[action&.to_sym] = validator 
      end
    end

    private

    def _stateful_sanitizers
      @_stateful_sanitizers ||= {}
    end

    def _stateful_validators
      @_stateful_validators ||= {}
    end
  end

  protected

  attr_accessor :model

  def sanitizer
    return @sanitizer if @sanitizer

    details = StatefulValidator::Controller.sanitizer self, params[:action]
    return nil unless details

    permitted = request.params[details[:param_key]]

    @sanitizer = details[:klass].new permitted, controller: self, model: self.model
    @sanitizer.set_ids_from_params! params, details[:ids]
    @sanitizer
  end

  def validator
    return @validator if @validator

    details = StatefulValidator::Controller.validator self, params[:action]
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

    StatefulValidator::Controller.auto_fill_validations self, validations 
  end

  def populate(&block)
    return unless errors.empty?

    ActiveRecord::Base.transaction do 
      begin
        block.call(sanitizer)
      rescue ActiveModel::ValidationError => e
        errors.merge! e.errors
      rescue ActiveRecord::RecordInvalid => e
        errors.merge! e.record.errors
      end

      raise ActiveRecord::Rollback unless errors.empty?
    end
  end

  private

end