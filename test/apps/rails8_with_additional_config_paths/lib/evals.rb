class Evals
  def evals(something)
    instance_eval "plain string - no warning" 
    instance_eval "interpolated #{string} - warning"
    instance_eval anything_else # no warning

    eval anything # warning

    self.class.class_eval do
      # no warning
    end

    if [1, 2, 3].include? code
      eval code # no warning
    end

    eval "interpolate #{something}"
  end

  def safe_strings
    ["good", "fine"].each do |suffix|
      class_eval <<-METHODS
        def method_that_is_#{suffix}
          puts suffix
        end
      METHODS
    end
  end

  class << self
    def defs_eval(string)
      eval("foo #{string}")
    end
  end

  def Object.object_defs_eval(string)
    eval("foo #{string}")
  end

  def @ivar.ivar_def_eval(string)
    eval("foo #{string}")
  end

  lvar = Object.new
  def lvar.lvar_def_eval(string)
    eval("foo #{string}")
  end
end
