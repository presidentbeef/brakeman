require './lib/brakeman/version'
require './gem_common'

Gem::Specification.new do |s|
  s.name = %q{brakeman}
  s.version = Brakeman::Version
  s.authors = ["Justin Collins"]
  s.email = "gem@brakeman.org"
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis."
  s.homepage = "https://brakemanscanner.org"
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

  if File.exist? 'bundle/load.rb'
    # Pull in vendored dependencies
    s.files << 'bundle/load.rb'

    s.files += Dir['bundle/ruby/*/gems/**/*'].reject do |path|
      # Skip unnecessary files in dependencies
      path =~ /^bundle\/ruby\/\d\.\d\.\d\/gems\/[^\/]+\/(Rakefile|benchmark|bin|doc|example|man|site|spec|test)/
    end
  else
    Brakeman::GemDependencies.dev_dependencies(s) unless ENV['BM_PACKAGE']
    Brakeman::GemDependencies.base_dependencies(s)
    Brakeman::GemDependencies.extended_dependencies(s)
  end
end
