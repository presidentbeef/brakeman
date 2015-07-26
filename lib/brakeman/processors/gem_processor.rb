require 'brakeman/processors/lib/basic_processor'

#Processes Gemfile and Gemfile.lock
class Brakeman::GemProcessor < Brakeman::BasicProcessor

  def initialize *args
    super
    @gem_name_version = /^\s*([-_+.A-Za-z0-9]+) \((\w(\.\w+)*)\)/
  end

  def process_gems src, gem_lock = nil
    process src

    if gem_lock
      process_gem_lock gem_lock
    end

    @tracker.config.set_rails_version
  end

  def process_call exp
    if exp.target == nil and exp.method == :gem
      gem_name = exp.first_arg
      return exp unless string? gem_name

      gem_version = exp.second_arg

      version = if string? gem_version
                  gem_version.value
                else
                  nil
                end

      @tracker.config.add_gem gem_name.value, version, 'Gemfile', exp.line
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
      @tracker.config.add_gem $1, $2, file, line_num
    end
  end
end
