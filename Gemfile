source "https://rubygems.org"

gemspec :name => "brakeman"

unless ENV['BM_PACKAGE']
  group :test do
    gem 'rake'
    gem 'minitest'
    gem 'prism'
  end
end
