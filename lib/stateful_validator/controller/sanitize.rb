require 'active_support/concern'

module StatefulValidator::Controller::Sanitize
  extend ActiveSupport::Concern

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

    def action_sanitizer(klass, options = {})
      @action_sanitizer = klass ? __prepare_sanitizer(klass, options) : nil
    end

    alias_method :sanitize_with, :action_sanitizer

    def _lookup_sanitizer(opts)
      StatefulValidator::Utilities.lookup _sanitizers, opts
    end

    protected

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

      sanitizers << StatefulValidator::Controller::SanitizerListWrapper.new(sanitizers.dup, details[:klass])
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
end