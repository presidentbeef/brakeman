#Contains a couple shared methods for Processors.
module Brakeman::ProcessorHelper
  def process_all exp
    exp.each_sexp do |e|
      process e
    end
  end

  #Sets the current module.
  def process_module exp
    module_name = class_name(exp[1]).to_s
    prev_module = @current_module

    if prev_module
      @current_module = "#{prev_module}::#{module_name}"
    else
      @current_module = module_name
    end

    process exp[2]

    @current_module = prev_module

    exp
  end

  #Returns a class name as a Symbol.
  def class_name exp
    case exp
    when Sexp
      case exp.node_type
      when :const
        exp[1]
      when :lvar
        exp[1].to_sym
      when :colon2
        "#{class_name(exp[1])}::#{exp[2]}".to_sym
      when :colon3
        "::#{exp[1]}".to_sym
      when :call
        process exp
      when :self
        @current_class || @current_module || nil
      else
        raise "Error: Cannot get class name from #{exp}"
      end
    when Symbol
      exp
    when nil
      nil
    else
      raise "Error: Cannot get class name from #{exp}"
    end
  end
end
