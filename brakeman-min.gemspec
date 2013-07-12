require './lib/brakeman/version'

Gem::Specification.new do |s|
  s.name = %q{brakeman-min}
  s.version = Brakeman::Version
  s.authors = ["Justin Collins"]
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis. This version of the gem only requires the minimum number of dependencies. Use the 'brakeman' gem for a full install."
  s.homepage = "http://brakemanscanner.org"
  s.files = ["bin/brakeman", "CHANGES", "WARNING_TYPES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["brakeman"]
  s.license = "MIT"
  s.add_dependency "ruby_parser", "~>3.2.2"
  s.add_dependency "ruby2ruby", "~>2.0.5"
  s.add_dependency "multi_json", "~>1.2"
end
