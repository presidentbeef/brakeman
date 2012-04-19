require 'thread'
require 'brakeman/differ'

#Collects up results from running different checks.
#
#Checks can be added with +Check.add(check_class)+
#
#All .rb files in checks/ will be loaded.
class Brakeman::Checks
  @checks = []

  attr_reader :warnings, :controller_warnings, :model_warnings, :template_warnings, :checks_run

  #Add a check. This will call +_klass_.new+ when running tests
  def self.add klass
    @checks << klass
  end

  def self.checks
    @checks
  end

  #No need to use this directly.
  def initialize options = { }
    if options[:min_confidence]
      @min_confidence = options[:min_confidence]
    else
      @min_confidence = Brakeman.get_defaults[:min_confidence]
    end

    @warnings = []
    @template_warnings = []
    @model_warnings = []
    @controller_warnings = []
    @checks_run = []
  end

  #Add Warning to list of warnings to report.
  #Warnings are split into four different arrays
  #for template, controller, model, and generic warnings.
  #
  #Will not add warnings which are below the minimum confidence level.
  def add_warning warning
    unless warning.confidence > @min_confidence
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
  end

  #Return a hash of arrays of new and fixed warnings
  #
  #    diff = checks.diff old_checks
  #    diff[:fixed]  # [...]
  #    diff[:new]    # [...]
  def diff other_checks
    my_warnings = self.all_warnings
    other_warnings = other_checks.all_warnings
    Brakeman::Differ.new(my_warnings, other_warnings).diff
  end

  #Return an array of all warnings found.
  def all_warnings
    @warnings + @template_warnings + @controller_warnings + @model_warnings
  end

  #Run all the checks on the given Tracker.
  #Returns a new instance of Checks with the results.
  def self.run_checks tracker
    if tracker.options[:parallel_checks]
      self.run_checks_parallel tracker
    else
      self.run_checks_sequential tracker
    end
  end

  #Run checks sequentially
  def self.run_checks_sequential tracker
    check_runner = self.new :min_confidence => tracker.options[:min_confidence]

    @checks.each do |c|
      check_name = get_check_name c

      #Run or don't run check based on options
      unless tracker.options[:skip_checks].include? check_name or 
        (tracker.options[:run_checks] and not tracker.options[:run_checks].include? check_name)

        Brakeman.notify " - #{check_name}"

        check = c.new(tracker)
        check.run_check

        check.warnings.each do |w|
          check_runner.add_warning w
        end

        #Maintain list of which checks were run
        #mainly for reporting purposes
        check_runner.checks_run << check_name[5..-1]
      end
    end

    check_runner
  end

  #Run checks in parallel threads
  def self.run_checks_parallel tracker
    threads = []
    
    check_runner = self.new :min_confidence => tracker.options[:min_confidence]

    @checks.each do |c|
      check_name = get_check_name c

      #Run or don't run check based on options
      unless tracker.options[:skip_checks].include? check_name or 
        (tracker.options[:run_checks] and not tracker.options[:run_checks].include? check_name)

        Brakeman.notify " - #{check_name}"

        threads << Thread.new do
          begin
            check = c.new(tracker)
            check.run_check
            check.warnings
          rescue Exception => e
            Brakeman.notify "[#{check_name}] #{e}"
            []
          end
        end

        #Maintain list of which checks were run
        #mainly for reporting purposes
        check_runner.checks_run << check_name[5..-1]
      end
    end

    threads.each { |t| t.join }

    Brakeman.notify "Checks finished, collecting results..."

    #Collect results
    threads.each do |thread|
      thread.value.each do |warning|
        check_runner.add_warning warning
      end
    end

    check_runner
  end

  private

  def self.get_check_name check_class
    check_class.to_s.split("::").last
  end
end

#Load all files in checks/ directory
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/checks/*.rb").sort.each do |f| 
  require f.match(/(brakeman\/checks\/.*)\.rb$/)[0]
end
