require 'brakeman/processors/base_processor'

#Processes Gemfile and Gemfile.lock
class Brakeman::GemProcessor < Brakeman::BaseProcessor

  def initialize *args
    super
    @gem_name_version = /^\s*([-_+.A-Za-z0-9]+) \((\w(\.\w+)*)\)/
    @tracker.config[:gems] ||= {}
  end

  def process_gems src, gem_lock = nil
    process src

    if gem_lock
      process_gem_lock gem_lock
      @tracker.config[:rails_version] = @tracker.config[:gems][:rails]
    elsif @tracker.config[:gems][:rails] =~ /(\d+.\d+.\d+)/
      @tracker.config[:rails_version] = $1
    end

    if @tracker.options[:rails3].nil? and @tracker.options[:rails4].nil? and @tracker.config[:rails_version]
      if @tracker.config[:rails_version].start_with? "3"
        @tracker.options[:rails3] = true
        Brakeman.notify "[Notice] Detected Rails 3 application"
      elsif @tracker.config[:rails_version].start_with? "4"
        @tracker.options[:rails3] = true
        @tracker.options[:rails4] = true
        Brakeman.notify "[Notice] Detected Rails 4 application"
      end
    end

    if @tracker.config[:gems][:rails_xss]
      @tracker.config[:escape_html] = true

      Brakeman.notify "[Notice] Escaping HTML by default"
    end
  end

  def process_call exp
    if exp.target == nil and exp.method == :gem
      gem_name = exp.first_arg
      return exp unless string? gem_name

      gem_version = exp.second_arg

      if string? gem_version
        @tracker.config[:gems][gem_name.value.to_sym] = gem_version.value
      else
        @tracker.config[:gems][gem_name.value.to_sym] = ">=0.0.0"
      end
    end

    exp
  end

  def process_gem_lock gem_lock
    gem_lock.each_line do |line|
      set_gem_version line
    end
  end

  # Supports .rc2 but not ~>, >=, or <=
  def set_gem_version line
    if line =~ @gem_name_version
      @tracker.config[:gems][$1.to_sym] = $2
    end
  end
end
