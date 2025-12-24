source "https://rubygems.org"

gemspec :name => "brakeman"

unless ENV['BM_PACKAGE']
  group :test do
    gem 'rake'
    gem 'minitest', '>= 6.0'
  end
end
