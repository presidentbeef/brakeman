require 'processors/base_processor'

#Processes Gemfile and Gemfile.lock
class GemProcessor < BaseProcessor
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
  end

  def process_call exp
    if exp[1] == nil and exp[2] == :gem
      args = exp[3][1..-1]

      if sexp? args[1]
        @tracker.config[:gems][args[0][1].to_sym] = args[1][1]
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
