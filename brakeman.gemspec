require './lib/version'

Gem::Specification.new do |s|
  s.name = %q{brakeman-min}
  s.version = Version
  s.authors = ["Justin Collins"]
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = <<-DESC
  Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis.
  This gem only supports tab output to minimize dependencies. It does not include erubis or haml in its dependencies.
  To use either of these, please install the required gems manually.
  DESC
  s.homepage = "http://github.com/presidentbeef/brakeman"
  s.files = ["bin/brakeman", "WARNING_TYPES", "FEATURES", "README.md"] + Dir["lib/**/*.rb"] + Dir["lib/format/*.css"]
  s.executables = ["brakeman"]
  s.add_dependency "activesupport", "~>2.2"
  s.add_dependency "ruby2ruby", "~>1.2.4" 
end
