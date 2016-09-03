# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ctes_in_my_pg/version'

Gem::Specification.new do |spec|
  spec.name          = "ctes_in_my_pg"
  spec.version       = CtesInMyPg::VERSION
  spec.authors       = ["Kyle Murphy"]
  spec.email         = ["kmurph73@gmail.com"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/shmay"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_development_dependency 'bourne', '~> 1.3.0'

  spec.add_dependency 'pg'
  spec.add_dependency 'activerecord', '>= 4.0.0'
  spec.add_dependency 'arel', '>= 4.0.1'

  spec.add_development_dependency 'm'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'byebug'

end
