class Evals
  def evals
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
  end
end
