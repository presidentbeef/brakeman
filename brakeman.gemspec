require './lib/brakeman/version'

Gem::Specification.new do |s|
  s.name = %q{brakeman}
  s.version = Brakeman::Version
  s.authors = ["Justin Collins"]
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis."
  s.homepage = "http://brakemanscanner.org"
  s.files = ["bin/brakeman", "CHANGES", "WARNING_TYPES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["brakeman"]
  s.license = "MIT"
  s.add_dependency "ruby_parser", "~>3.2.2"
  s.add_dependency "ruby2ruby", "~>2.0.5"
  s.add_dependency "terminal-table", "~>1.4"
  s.add_dependency "fastercsv", "~>1.5"
  s.add_dependency "highline", "~>1.6.19"
  s.add_dependency "erubis", "~>2.6"
  s.add_dependency "haml", ">=3.0", "<5.0"
  s.add_dependency "sass", "~>3.0"
  s.add_dependency "slim", ">=1.3.6", "<3.0"
  s.add_dependency "multi_json", "~>1.2"
end
