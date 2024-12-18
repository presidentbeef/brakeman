#!/usr/bin/env ruby
require 'fileutils'
bundle_exclude = %w[io-console prism racc strscan]

puts 'Packaging Brakeman gem...'

system 'rm -rf bundle Gemfile.lock brakeman-*.gem' and
  system 'BM_PACKAGE=true bundle install --standalone'

abort "No bundle installed" unless Dir.exist? 'bundle'

File.delete "bundle/bundler/setup.rb"
Dir.delete "bundle/bundler"

File.open "bundle/load.rb", "w" do |f|
  f.puts "path = File.expand_path('../..', __FILE__)"

  Dir["bundle/ruby/**/lib"].each do |dir|
    if bundle_exclude.any? { |gem_name| dir.include? gem_name }
      FileUtils.rm_rf(File.expand_path('..', dir))
    else
      f.puts %Q[$:.unshift "\#{path}/#{dir}"]
    end
  end
end

system "BM_PACKAGE=true gem build brakeman.gemspec"
