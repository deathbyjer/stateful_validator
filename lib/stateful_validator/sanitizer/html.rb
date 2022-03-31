module StatefulValidator::Sanitizer::Html

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def sanitize(str)
      str = str.to_s.strip
      return str unless defined?(ActionController::Base)

      ActionController::Base.helpers&.sanitize(str) || str
    end

    def strip_tags(str)
      return str unless defined?(ActionController::Base)

      ActionController::Base.helpers&.strip_tags(str) || str
    end

    def strip_links(str)
      return str unless defined?(ActionController::Base)

      ActionController::Base.helpers&.strip_links(str) || str
    end
  end
end