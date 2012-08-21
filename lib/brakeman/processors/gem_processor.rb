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
      args = exp.args

      if string? args.second
        @tracker.config[:gems][args.first.value.to_sym] = args.second.value
      else
        @tracker.config[:gems][args.first.value.to_sym] = ">=0.0.0"
      end
    end

    exp
  end

  def get_rails_version gem_lock
    if gem_lock =~ /\srails \((\d+.\d+.\d+)\)$/
      @tracker.config[:rails_version] = $1
    end
  end
end
