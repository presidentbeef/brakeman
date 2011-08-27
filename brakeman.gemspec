require './lib/version'

Gem::Specification.new do |s|
  s.name = %q{brakeman}
  s.version = Version
  s.authors = ["Justin Collins"]
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis."
  s.homepage = "http://brakemanscanner.org"
  s.files = ["bin/brakeman", "WARNING_TYPES", "FEATURES", "README.md"] + Dir["lib/**/*.rb"] + Dir["lib/format/*.css"]
  s.executables = ["brakeman"]
  s.add_dependency "activesupport", "~>2.2"
  s.add_dependency "ruby2ruby", "~>1.2.4" 
  s.add_dependency "ruport", "~>1.6.3"
  s.add_dependency "erubis", "~>2.6.5"
  s.add_dependency "haml", "~>3.0.12"
end
