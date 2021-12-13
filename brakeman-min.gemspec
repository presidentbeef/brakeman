require './lib/brakeman/version'
require './gem_common'

Gem::Specification.new do |s|
  s.name = %q{brakeman-min}
  s.version = Brakeman::Version
  s.authors = ["Justin Collins"]
  s.email = "gem@brakeman.org"
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis. This version of the gem only requires the minimum number of dependencies. Use the 'brakeman' gem for a full install."
  s.homepage = "http://brakemanscanner.org"
  s.files = ["bin/brakeman", "CHANGES.md", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["brakeman"]
  s.license = "Brakeman Public Use License"
  s.required_ruby_version = '>= 2.5.0'

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/presidentbeef/brakeman/issues",
    "changelog_uri"     => "https://github.com/presidentbeef/brakeman/releases",
    "documentation_uri" => "https://brakemanscanner.org/docs/",
    "homepage_uri"      => "https://brakemanscanner.org/",
    "mailing_list_uri"  => "https://gitter.im/presidentbeef/brakeman",
    "source_code_uri"   => "https://github.com/presidentbeef/brakeman",
    "wiki_uri"          => "https://github.com/presidentbeef/brakeman/wiki"
  }

  Brakeman::GemDependencies.dev_dependencies(s)
  Brakeman::GemDependencies.base_dependencies(s)
end
