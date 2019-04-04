$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "apicasso_brush/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "apicasso_brush"
  spec.version     = ApicassoBrush::VERSION
  spec.authors     = ["Fernando Bellincanta"]
  spec.email       = ["ervalhous@hotmail.com"]
  spec.homepage    = "https://github.com/ErvalhouS/apicasso_brush"
  spec.summary     = "APIcasso Brush is a client to consume data from microservices built upon APIcasso. It makes PORO classes supercharged by injecting Rails-like behavior through the methods:"
  spec.description = "Instead of translating method calls into ORM, APIcasso Brush retrieves it's data from your configured service. This makes it possible to make a convergent application, that gets data from multiple API sources."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "> 5"

  spec.add_development_dependency "sqlite3"
end
