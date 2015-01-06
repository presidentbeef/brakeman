require 'brakeman/processors/lib/basic_processor'

#Processes Gemfile and Gemfile.lock
class Brakeman::GemProcessor < Brakeman::BasicProcessor

  def initialize *args
    super
    @gem_name_version = /^\s*([-_+.A-Za-z0-9]+) \((\w(\.\w+)*)\)/
    @tracker.config[:gems] ||= {}
  end

  def process_gems src, gem_lock = nil
    process src

    if gem_lock
      process_gem_lock gem_lock
      @tracker.config[:rails_version] = @tracker.config[:gems][:rails][:version] if @tracker.config[:gems][:rails]
    elsif @tracker.config[:gems] && @tracker.config[:gems][:rails] && @tracker.config[:gems][:rails][:version] =~ /(\d+.\d+.\d+)/
      @tracker.config[:rails_version] = $1
    else
      @tracker.config[:rails_version] = nil
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
        @tracker.config[:gems][gem_name.value.to_sym] = { :version => gem_version.value.to_s, :file => 'Gemfile', :line => exp.line }
      else
        @tracker.config[:gems][gem_name.value.to_sym] = { :version => nil, :file => 'Gemfile' , :line => exp.line }
      end
    end

    exp
  end

  def process_gem_lock gem_lock
    line_num = 1
    gem_lock.each_line do |line|
      set_gem_version_and_file line, 'Gemfile.lock', line_num
      line_num += 1
    end
  end

  # Supports .rc2 but not ~>, >=, or <=
  def set_gem_version_and_file line, file, line_num
    if line =~ @gem_name_version
      @tracker.config[:gems][$1.to_sym] = { :version => $2, :file => file, :line => line_num }
    end
  end
end
