class StatefulValidator::Sanitizer
  require 'stateful_validator/sanitizer/html'

  attr_accessor :params
  attr_accessor :controller
  attr_accessor :model

  include Html

  def initialize(params, options = {})
    self.params = params || {}
    self.controller = options[:controller]
    self.model = options[:model] || self.controller&.model
  end

  def set_ids_from_params!(params, ids)
    return unless ids

    ids = ids.keys if ids.is_a?(Hash)
    ids = [ids] unless ids.is_a?(Array)

    self.params.merge! params.permit(*ids).to_h.compact

    self
  end

  def has?(key)
    return true if params.key?(key.to_sym)
    return true if params.key?("#{key}_id".to_sym)

    false
  end
end