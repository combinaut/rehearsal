$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rehearsal/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "combinaut_rehearsal"
  s.version     = Rehearsal::VERSION
  s.authors     = ["Ryan Wallace", "Nicholas Jakobsen"]
  s.email       = ["hello@combinaut.com"]
  s.homepage    = "http://github.com/combinaut/rehearsal"
  s.summary     = "Rack Middleware that allows model changes to be previewed without persisting them to the database"
  s.description = "Rehearsal is a Rack Middleware gem that allows model changes to be previewed without persisting them to the database. It achieves this by intercepting the original update request and spawning a second request to Rails for a preview, wrapping both in a single database transaction that is rolled back after the preview is generated."

  s.files = Dir["{app}/**/*"] + Dir["{lib}/**/*"] + ["MIT-LICENSE", "README.md"]

  s.add_dependency "rails", ">= 4.2"
  s.add_development_dependency 'combustion', '~> 0.7.0'
  s.add_development_dependency 'rspec-rails', '~> 3.6'
  s.add_development_dependency 'sqlite3'
end
