#!/bin/env ruby
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/lib"

trap("INT") do
  $stderr.puts "\nInterrupted - exiting."
  exit!
end

require 'benchmark'
require 'brakeman'
require 'brakeman/options'

#Runs scans on one or more Rails apps and collects timing results
class Conductor
  attr_reader :results #All the timing results in a big hash

  #Creates new Conductor to scan the given paths.
  #
  #+options+ should be options as returned by Brakeman::Options.parse
  #
  #+paths+ should be an array of paths.
  def initialize options, paths
    @options = {:conductor_limit => 10}.merge! options
    @paths = paths
    @scans = {}
    @results = { :ruby_version => RUBY_DESCRIPTION, :scans => @scans }

    @results[:scanner_load_time] = Benchmark.measure do
      require 'brakeman/scanner'
    end
  end

  #Runs scans on the paths set when the Conductor was created.
  #
  #Returns self.
  #
  #The result of a single scan is stored in a hash that looks like this:
  #
  #    { :path => String,       #Path that was scanned
  #      :start_time => Time,   #Time at which scan started
  #      :end_time => Time,     #Time at which scan finished
  #      :times => {            #All timings collected via Brakeman.benchmark
  #        :total_time => Tms,
  #        ...
  #      }
  #    }
  #
  def run_scans
    @done = false
    watcher = Thread.new do
      until @done do
        ps = "ps -p #{Process.pid} -opcpu | sed '1 d'"
        ps_out = `#{ps}`
        puts "\n#{Time.now} #{Process.times} #{Thread.list.count} threads #{ps_out}"
        sleep 1
      end
    end

    @results[:start_time] = Time.now

    @results[:total_time] = Benchmark.measure do
      @paths.each do |path|
        Brakeman.clear_benchmarks #Reset times

        options = @options.merge :app_path => path

        @scans[path] = { :path => path, :start_time => Time.now }
        notify "Started scanning #{path} at #{@scans[path][:start_time]}"

        tracker = nil
        #Benchmark the scan
        Brakeman.benchmark :total_time do
          tracker = Brakeman.run options
        end

        @scans[path][:end_time] = Time.now
        notify "Finished scanning #{path} at #{@scans[path][:end_time]}"

        @scans[path][:times] = Brakeman.benchmarks
        @scans[path][:controllers] = tracker.controllers.length
        @scans[path][:templates] = tracker.templates.length
        @scans[path][:models] = tracker.models.length
        @scans[path][:errors] = tracker.errors.length
      end
    end

    @done = true
    @results[:end_time] = Time.now
    watcher.join

    self
  end

  #Output message unless :quiet => true
  def notify msg
    $stderr.puts msg unless @options[:quiet]
  end

  #Generate a report as a string
  def report
    output = [ summary ]

    @scans.keys.sort.each do |path|
      output << format_results(@scans[path])
    end

    output.join("\n#{"-" * 55}\n") << "\n#{"=" * 55}"
  end

  #Output summary as a string
  def summary
    "======================================================\n" <<
    "Used #{@results[:ruby_version]}\n" <<
    "Started at #{@results[:start_time]}\n" <<
    "Finished at #{@results[:end_time]}\n" <<
    "Scanned #{@results[:scans].length} path(s)\n" <<
    "Total time: #{@results[:total_time].total}s"
  end

  #Format the results from a single scan
  def format_results results
    output = [ "#{results[:path]} @ #{results[:start_time]}",
      "  #{results[:controllers]} controllers, #{results[:models]} models, #{results[:templates]} templates, #{results[:errors]} errors"
    ]

    #Report timings from longest to shortest
    results[:times].to_a.sort_by { |name, time| time.total }.reverse[0...@options[:conductor_limit]].each do |result|
      name = result[0].to_s
      output << "  #{name}: #{result[1].format("%t %r").rjust(50 - name.length)}"
    end

    output.join "\n"
  end
end

if __FILE__ == $0
  options, _ = Brakeman::Options.parse! ARGV

  abort "Please supply the path to at least one Rails app" if ARGV.empty?

  puts Conductor.new(options, ARGV).run_scans.report
end
