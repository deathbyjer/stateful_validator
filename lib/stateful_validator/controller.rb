require 'active_support/concern'

module StatefulValidator::Controller
  %w[sanitizer_list_wrapper sanitize validate].each do |filename|
    require File.dirname(__FILE__) + "/controller/#{filename}"
  end

  extend ActiveSupport::Concern

  included do 
    include Sanitize
    include Validate
  end

  module ClassMethods
    def method_added(action)
      _sanitizers[action] = @action_sanitizer if @action_sanitizer
      _validators[action] = @action_validator if @action_validator

      @action_sanitizer = @action_validator = nil
    end
  end

  protected

  attr_accessor :model

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

  def populate_for_all(opts = {}, alt_opts = {}, &block)
    return if has_errors?

    opts = clean_populate_block_options opts, alt_opts

    wrap_populate_block_inside_transaction do
      begin
        block.call(sanitizers(opts))
      rescue StatefulValidator::ValidationError => e
        errors(opts.merge(index: :all)).merge! e.errors
      rescue ActiveRecord::RecordInvalid => e
        errors(opts.merge(index: :all)).merge! e.record.errors
      end

      raise ActiveRecord::Rollback unless errors(opts.merge(index: :all)).empty?
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
        rescue StatefulValidator::ValidationError => e
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
        safe_params = params.to_unsafe_hash.with_indifferent_access
      elsif params[key].is_a?(Array)
        safe_params = params.require(key)
        safe_params.map!(&:permit!)
        safe_params.map!.with_index do |p, i| 
          [i, p.to_hash.with_indifferent_access] 
        end

        safe_params = { key => safe_params.to_h.with_indifferent_access }
      else
        safe_params = params.permit(key => {}).to_hash.with_indifferent_access
      end
    end

    # Get just the part of the has we need
    unless top_level_params
      safe_params = safe_params[key.to_s] || safe_params[key.to_sym] if safe_params.is_a?(Hash)
    end
    
    return list ? [] : [nil] unless safe_params.present?

    return safe_params.map{|p| p.is_a?(Hash) ? p.with_indifferent_access : p } if safe_params.is_a?(Array)

    return [safe_params] unless safe_params.is_a?(Hash)
    return [safe_params.with_indifferent_access] unless list

    safe_params.to_a.map do |k, p|
      { id: k }.merge(p).with_indifferent_access
    end
  end
end
