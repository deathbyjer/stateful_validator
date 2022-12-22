require 'active_support/concern'

module StatefulValidator::Controller
  %w[sanitizer_list_wrapper validate].each do |filename|
    require File.dirname(__FILE__) + "/controller/#{filename}"
  end

  extend ActiveSupport::Concern

  included do 
    include Validate
  end

  module ClassMethods
    def sanitizer(klass = nil, options = {})
      return _sanitizers[nil] if klass.nil?

      options = { action: options[:only]}.merge(options)

      sanitizer = __prepare_sanitizer klass, options
      StatefulValidator::Utilities.assign_to_lookup _sanitizers, options, sanitizer
    end

    def named_sanitizer(name, klass = nil, options = {})
      options = options.merge(name: name)
      sanitizer klass, options
    end

    def named_sanitizers(name, klass, options = {})
      options = options.merge(name: name, list: true)
      sanitizer klass, options
    end
    
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
    

    def _lookup_sanitizer(opts)
      StatefulValidator::Utilities.lookup _sanitizers, opts
    end

    def method_added(action)
      _sanitizers[action] = @action_sanitizer if @action_sanitizer
      _validators[action] = @action_validator if @action_validator

      @action_sanitizer = @action_validator = nil
    end

    def action_sanitizer(klass, options = {})
      @action_sanitizer = klass ? __prepare_sanitizer(klass, options) : nil
    end

    private

    def _sanitizers
      @_sanitizers ||= { actions: {}, names: {} }
    end

    def __prepare_sanitizer(klass, options)
      unless klass.ancestors.include?(StatefulValidator::Sanitizer)
        raise StatefulValidator::Errors::IllegalSanitizer
      end

      {
        klass: klass,
        key: options[:param_key] || klass.name.underscore.split("_")[0..-2].join("_").to_sym,
        top_level_params: options[:param_key] === false,
        ids: options[:ids],
        list: options[:list] ? true : false
      }.compact
    end
  end

  protected

  attr_accessor :model

  def sanitizer(opts = {})
    sanitizers(opts)[opts[:index].to_i]
  end

  def sanitizers(opts = {})
    opts = opts.merge(action: params[:action].to_sym)
    @sanitizers ||= { default: [], names: {} }

    # Lookup a generated sanitizer
    found_sanitizers = StatefulValidator::Utilities.lookup @sanitizers, opts.merge(no_default: true)
    return found_sanitizers[0...-1] if found_sanitizers.present?

    # Find the correct sanitizer details
    details = self.class._lookup_sanitizer opts
    sanitizers = []

    # If we found details, then generate the sanitizers
    if details
      param_list = param_list_for_population(key: details[:key], top_level_params: details[:top_level_params], list: details[:list])

      sanitizers = param_list.map do |p|
        sanitizer = details[:klass].new(p, controller: self)
        sanitizer.set_ids_from_params! params, details[:ids]
        sanitizer
      end

      sanitizers << SanitizerListWrapper.new(sanitizers.dup, details[:klass])
    end

    StatefulValidator::Utilities.assign_to_lookup @sanitizers, opts, sanitizers
    sanitizers[0...-1]
  end

  def merged_sanitizers(opts)
    opts = opts.merge(action: params[:action])
    sanitizers(opts) # Ensure it is all built

    found_sanitizers = StatefulValidator::Utilities.lookup @sanitizers, opts
    found_sanitizers.last
  end

  def populate(opts = {}, alt_opts = {}, &block)
    return if has_errors?

    opts = clean_populate_block_options opts, alt_opts

    wrap_populate_block_inside_transaction do
      begin
        block.call(sanitizer(opts))
      rescue StatefulValidator::ValidationError => e
        errors(opts).merge! e.errors
      rescue ActiveRecord::RecordInvalid => e
        errors(opts).merge! e.record.errors
      end

      raise ActiveRecord::Rollback unless errors(opts).empty?
    end
  end

  def populate_for_each(opts = {}, alt_opts = {}, &block)
    return if has_errors?

    opts = clean_populate_block_options opts, alt_opts

    wrap_populate_block_inside_transaction do
      sanitizers(opts).each.with_index do |sanitizer, index|
        @__populating = index

        local_errors = errors(opts.merge(index: index))
        begin
          block.call(sanitizer)
        rescue ValidationError => e
          local_errors.merge! e.errors
        rescue ActiveRecord::RecordInvalid => e
          local_errors.merge! e.record.errors
        ensure
          @__populating = nil
        end

        raise ActiveRecord::Rollback unless local_errors.empty?
      end
    end
  end

  def populate_once(options = {}, alt_opts = {}, &block)
    options = clean_populate_block_options options, alt_opts

    return if has_errors?
    return if options[:at_front] && @__populating != 0
    return if !options[:at_front] && @__populating != sanitizers.length - 1

    block.call(sanitizers(options)[@__populating])
  end

  private

  # We want to wrap everything in the top-level populate block
  def wrap_populate_block_inside_transaction(&block)
    return block.call if @populate_already_in_transaction

    @populate_already_in_transaction = true
    ActiveRecord::Base.transaction { block.call }
    @populate_already_in_transaction = nil
  end

  def clean_populate_block_options(options, alt_options = {})
    options = { name: options } if options.is_a?(Symbol)

    options = {} unless options.is_a?(Hash)
    alt_options = {} unless alt_options.is_a?(Hash)

    options = options.merge(alt_options)
    options
  end

  def param_list_for_population(key:, list: false, top_level_params: false)
    # We need to always return something
    safe_params = params

    # If Parameters, then permit the parameters we need and conver to hash
    if params.is_a?(ActionController::Parameters)
      if top_level_params
        safe_params = params.to_unsafe_hash
      elsif params[key].is_a?(Array)
        safe_params = params.require(key)
        safe_params.map!(&:permit!)
        safe_params.map!.with_index do |p, i| 
          [i, p.to_hash] 
        end

        safe_params = { key => safe_params.to_h }
      else
        safe_params = params.permit(key => {}).to_hash
      end
    end

    # Get just the part of the has we need
    unless top_level_params
      safe_params = safe_params[key.to_s] || safe_params[key.to_sym] if safe_params.is_a?(Hash)
    end
    
    return list ? [] : [nil] unless safe_params.present?

    return safe_params if safe_params.is_a?(Array)

    return [safe_params] unless safe_params.is_a?(Hash)
    return [safe_params.transform_keys(&:to_sym)] unless list

    safe_params.to_a.map do |k, p|
      { id: k }.merge(p).transform_keys(&:to_sym)
    end
  end
end
