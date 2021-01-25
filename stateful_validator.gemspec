
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "stateful_validator/version"

Gem::Specification.new do |spec|
  spec.name          = "stateful_validator"
  spec.version       = StatefulValidator::VERSION
  spec.authors       = ["Jeremy Linder"]
  spec.email         = ["deathbyjer@gmail.com"]

  spec.summary       = %q{Stateful validations that can be used in the controller}
  spec.description   = %q{While ActiveRecord validations are excellent at discerning data integrity, they should not (necessarily) be used for business logic checks, as those are appropriately bound to the controller, whose job it is to be aware of application state. Stateful Validators allow us to maintain a clean scheme of sanitizing and validating our input in a testable fashion.}
  #spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
end
