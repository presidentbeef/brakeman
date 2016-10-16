require 'brakeman/processors/lib/basic_processor'

#Processes Gemfile and Gemfile.lock
class Brakeman::GemProcessor < Brakeman::BasicProcessor

  def initialize *args
    super
    @gem_name_version = /^\s*([-_+.A-Za-z0-9]+) \((\w(\.\w+)*)\)/
  end

  def process_gems gem_files
    @gem_files = gem_files
    @gemfile = gem_files[:gemfile][:file]
    process gem_files[:gemfile][:src]

    if gem_files[:gemlock]
      process_gem_lock
    end

    @tracker.config.set_rails_version
  end

  def process_call exp
    if exp.target == nil
      if exp.method == :gem
        gem_name = exp.first_arg
        return exp unless string? gem_name

        gem_version = exp.second_arg

        version = if string? gem_version
                    gem_version.value
                  else
                    nil
                  end

        @tracker.config.add_gem gem_name.value, version, @gemfile, exp.line
      elsif exp.method == :ruby
        version = exp.first_arg
        if string? version
          @tracker.config.set_ruby_version version.value
        end
      end
    end

    exp
  end

  def process_gem_lock
    line_num = 1
    file = @gem_files[:gemlock][:file]
    @gem_files[:gemlock][:src].each_line do |line|
      set_gem_version_and_file line, file, line_num
      line_num += 1
    end
  end

  # Supports .rc2 but not ~>, >=, or <=
  def set_gem_version_and_file line, file, line_num
    if line =~ @gem_name_version
      @tracker.config.add_gem $1, $2, file, line_num
    end
  end
end
