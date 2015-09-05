require './lib/brakeman/version'
gem_priv_key = File.expand_path("~/.ssh/gem-private_key.pem")

Gem::Specification.new do |s|
  s.name = %q{brakeman-min}
  s.version = Brakeman::Version
  s.authors = ["Justin Collins"]
  s.email = "gem@brakeman.org"
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis. This version of the gem only requires the minimum number of dependencies. Use the 'brakeman' gem for a full install."
  s.homepage = "http://brakemanscanner.org"
  s.files = ["bin/brakeman", "CHANGES", "WARNING_TYPES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["brakeman"]
  s.license = "MIT"
  s.cert_chain  = ['brakeman-public_cert.pem']
  s.signing_key = gem_priv_key if File.exist? gem_priv_key and $PROGRAM_NAME =~ /gem\z/
  s.add_development_dependency "test-unit"
  s.add_dependency "ruby_parser", "~>3.7.0"
  s.add_dependency "ruby2ruby", ">=2.1.1", "<2.3.0"
  s.add_dependency "multi_json", "~>1.2"
end
