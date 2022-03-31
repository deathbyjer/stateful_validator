module StatefulValidator::Utilities
  class << self
    def get_or_set(lookup_hash, opts, value)
      found = lookup lookup_hash, opts.merge(no_default: true)
      assign_to_lookup(lookup_hash, opts, value) unless found
      found || value
    end

    def lookup(lookup_hash, options)
      name = options[:name]
      action = options[:action]

      # Use default if there are no names or actions, or if we allow it as a base
      default = !(name || action) || !options[:no_default]

      # First, check for a name match
      return lookup_hash[:names][name] if lookup_hash.fetch(:names, {})[name]
      # Next, check for an action match
      return lookup_hash[:actions][action] if lookup_hash.fetch(:actions, {})[action]

      # Otherwise, go with the default
      default ? lookup_hash[:default] : nil
    end

    def assign_to_lookup(lookup_hash, options, value)
      options[:default] ||= !(options[:name].present? || options[:action].present?)

      if lookup_hash[:names]
        lookup_hash[:names][options[:name]] = value if options[:name].present?
      end

      if lookup_hash[:actions]
        Array.wrap(options[:action]).each { |a| lookup_hash[:actions][a] = value }
      end

      lookup_hash[:default] = value if options[:default]
      value
    end
  end
end