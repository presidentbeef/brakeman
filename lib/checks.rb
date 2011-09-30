require 'thread'

#Collects up results from running different checks.
#
#Checks can be added with +Check.add(check_class)+
#
#All .rb files in checks/ will be loaded.
class Checks
  @checks = []

  attr_reader :warnings, :controller_warnings, :model_warnings, :template_warnings, :checks_run, :check_results

  #Add a check. This will call +_klass_.new+ when running tests
  def self.add klass
    @checks << klass
  end

  def self.checks
    @checks
  end

  #No need to use this directly.
  def initialize
    @warnings = []
    @template_warnings = []
    @model_warnings = []
    @controller_warnings = []
    @checks_run = []
    @check_results = Queue.new
  end

  #Add Warning to list of warnings to report.
  #Warnings are split into four different arrays
  #for template, controller, model, and generic warnings.
  def add_warning warning
    case warning.warning_set
    when :template
      @template_warnings << warning
    when :warning
      @warnings << warning
    when :controller
      @controller_warnings << warning
    when :model
      @model_warnings << warning
    else
      raise "Unknown warning: #{warning.warning_set}"
    end
  end

  #Run all the checks on the given Tracker.
  #Returns a new instance of Checks with the results.
  def self.run_checks tracker
    if OPTIONS[:parallel_checks]
      self.run_checks_parallel tracker
    else
      self.run_checks_sequential tracker
    end
  end

  #Run checks sequentially
  def self.run_checks_sequential tracker
    check_runner = self.new

    @checks.each do |c|
      #Run or don't run check based on options
      unless OPTIONS[:skip_checks].include? c.to_s or 
        (OPTIONS[:run_checks] and not OPTIONS[:run_checks].include? c.to_s)

        warn " - #{c}"

        check = c.new(tracker)
        check.run_check

        check.warnings.each do |w|
          check_runner.add_warning w
        end

        #Maintain list of which checks were run
        #mainly for reporting purposes
        check_runner.checks_run << c.to_s[5..-1]
      end
    end

    check_runner
  end

  #Run checks in parallel threads
  def self.run_checks_parallel tracker
    threads = []
    
    check_runner = self.new

    @checks.each do |c|
      #Run or don't run check based on options
      unless OPTIONS[:skip_checks].include? c.to_s or 
        (OPTIONS[:run_checks] and not OPTIONS[:run_checks].include? c.to_s)

        warn " - #{c}"

        threads << Thread.new do
          check = c.new(tracker)
          check.run_check
          check_runner.check_results << check.warnings unless check.warnings.empty?
        end

        #Maintain list of which checks were run
        #mainly for reporting purposes
        check_runner.checks_run << c.to_s[5..-1]
      end
    end

    threads.each { |t| t.join }

    until check_runner.check_results.empty?
      r = check_runner.check_results.pop
      r.each do |w|
        check_runner.add_warning w
      end
    end

    check_runner
  end
end

#Load all files in checks/ directory
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/checks/*.rb").sort.each do |f| 
  require f.match(/(checks\/.*)\.rb$/)[0]
end
