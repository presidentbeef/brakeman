#!/bin/env ruby
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/lib"

require 'benchmark'
require 'brakeman'
require 'brakeman/options'

options, _ = Brakeman::Options.parse! ARGV

abort "Please supply the path to at least one Rails app" if ARGV.empty?

trap("INT") do
  $stderr.puts "\nInterrupted - exiting."
  exit!
end

ARGV.each do |path|
  run_options = options.merge :app_path => path
  puts "Started scanning #{path} at #{Time.now}"

  result = Benchmark.measure do
    Brakeman.run run_options
  end

  puts "Finished scanning #{path} at #{Time.now}"
  puts "Scan time: #{result}"
end
