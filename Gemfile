source "https://rubygems.org"

gemspec :name => "brakeman"

gem "rake", "< 10.2.0"

# Slim v3.0.0 dropped support for Ruby <1.9.2.
if RUBY_VERSION < "1.9.2"
  gem "slim", ">=1.3.6", "< 3.0"
else
  gem "slim", ">=1.3.6"
end
