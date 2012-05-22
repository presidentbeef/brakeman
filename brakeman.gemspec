require './lib/brakeman/version'

Gem::Specification.new do |s|
  s.name = %q{brakeman}
  s.version = Brakeman::Version
  s.authors = ["Justin Collins"]
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis."
  s.homepage = "http://brakemanscanner.org"
  s.files = ["bin/brakeman", "WARNING_TYPES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["brakeman"]
  s.add_dependency "activesupport"
  s.add_dependency "i18n"
  s.add_dependency "ruby_parser", "2.3.1"
  s.add_dependency "ruby2ruby", "~>1.2"
  s.add_dependency "terminal-table", "~>1.4"
  s.add_dependency "fastercsv", "~>1.5"
  s.add_dependency "highline", "~>1.6"
  s.add_dependency "erubis", "~>2.6"
  s.add_dependency "haml", "~>3.0"
  s.add_dependency "json_pure"
end
