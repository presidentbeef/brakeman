require 'brakeman/processors/base_processor'

class Brakeman::FindAllCalls < Brakeman::BaseProcessor
  attr_reader :calls

  def initialize tracker
    super
    @current_class = nil
    @current_method = nil
    @in_target = false
    @calls = []
  end

  #Process the given source. Provide either class and method being searched
  #or the template. These names are used when reporting results.
  def process_source exp, klass = nil, method = nil, template = nil
    @current_class = klass
    @current_method = method
    @current_template = template
    process exp
  end

  #Process body of method
  def process_methdef exp
    process exp[3]
  end

  #Process body of method
  def process_selfdef exp
    process exp[4]
  end

  #Process body of block
  def process_rlist exp
    exp[1..-1].each do |e|
      process e
    end

    exp
  end

  def process_call exp
    target = get_target exp[1]
    
    if call? target
      already_in_target = @in_target
      @in_target = true
      process target
      @in_target = already_in_target
    end

    method = exp[2]
    process exp[3]
    
    if @current_template
      @calls << { :target => target, :method => method, :call => exp, :nested => @in_target, :location => [:template, @current_template]}
    else
      @calls << { :target => target, :method => method, :call => exp, :nested => @in_target, :location => [:class, @current_class, @current_method] }
    end

    exp
  end

  #Process an assignment like a call
  def process_attrasgn exp
    process_call exp
  end

  private

  #Gets the target of a call as a Symbol
  #if possible
  def get_target exp
    if sexp? exp
      case exp.node_type
      when :ivar, :lvar, :const
        exp[1]
      when :true, :false
        exp[0]
      when :lit
        exp[1]
      when :colon2
        class_name exp
      else
        exp
      end
    else
      exp
    end
  end
end
