require 'brakeman/processors/base_processor'

#Processes Gemfile and Gemfile.lock
class Brakeman::GemProcessor < Brakeman::BaseProcessor

  def initialize *args
    super

    @tracker.config[:gems] ||= {}
  end

  def process_gems src, gem_lock = nil
    process src

    if gem_lock
      get_rails_version gem_lock
      get_json_version gem_lock
    elsif @tracker.config[:gems][:rails] =~ /(\d+.\d+.\d+)/
      @tracker.config[:rails_version] = $1
    end

    if @tracker.config[:gems][:rails_xss]
      @tracker.config[:escape_html] = true

      Brakeman.notify "[Notice] Escaping HTML by default"
    end
  end

  def process_call exp
    if exp.target == nil and exp.method == :gem
      gem_name = exp.first_arg
      gem_version = exp.second_arg

      if string? gem_version
        @tracker.config[:gems][gem_name.value.to_sym] = gem_version.value
      else
        @tracker.config[:gems][gem_name.value.to_sym] = ">=0.0.0"
      end
    end

    exp
  end

  #Need to implement generic gem version check
  def get_version name, gem_lock
    match = gem_lock.match(/\s#{name} \((\d+.\d+.\d+.*)\)$/)
    match[1] if match
  end

  def get_rails_version gem_lock
    @tracker.config[:rails_version] = get_version("rails", gem_lock)
  end

  def get_json_version gem_lock
    @tracker.config[:gems][:json] = get_version("json", gem_lock)
    @tracker.config[:gems][:json_pure] = get_version("json_pure", gem_lock)
  end
end
