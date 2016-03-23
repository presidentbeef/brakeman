source "https://rubygems.org"

gemspec :name => "brakeman"

unless ENV['BM_PACKAGE']
  gem "rake", "< 10.2.0"
  gem "codeclimate-test-reporter", group: :test, require: nil
end
