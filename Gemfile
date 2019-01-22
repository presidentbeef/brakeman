source "https://rubygems.org"

gemspec :name => "brakeman"
gem "ruby_parser", "3.12.1", source: "file:///tmp/brakeman_test/repo"

unless ENV['BM_PACKAGE']
  gem "rake", "< 10.2.0"
  gem "codeclimate-test-reporter", group: :test, require: nil
  gem "json", "< 2.0", group: :test, require: nil # For Ruby 1.9.3 https://github.com/colszowka/simplecov/issues/511
end
