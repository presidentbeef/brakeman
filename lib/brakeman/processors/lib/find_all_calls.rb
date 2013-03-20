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
    process_all exp.body
  end

  #Process body of method
  def process_selfdef exp
    process_all exp.body
  end

  #Process body of block
  def process_rlist exp
    process_all exp
  end

  def process_call exp
    target = get_target exp.target
    
    if call? target
      already_in_target = @in_target
      @in_target = true
      process target
      @in_target = already_in_target
    end

    method = exp.method
    process_call_args exp

    call = { :target => target, :method => method, :call => exp, :nested => @in_target, :chain => get_chain(exp) }
    
    if @current_template
      call[:location] = [:template, @current_template]
    else
      call[:location] = [:class, @current_class, @current_method]
    end

    @calls << call

    exp
  end

  #Calls to render() are converted to s(:render, ...) but we would
  #like them in the call cache still for speed
  def process_render exp
    process exp.last if sexp? exp.last

    call = { :target => nil, :method => :render, :call => exp, :nested => false }

    if @current_template
      call[:location] = [:template, @current_template]
    else
      call[:location] = [:class, @current_class, @current_method]
    end

    @calls << call

    exp
  end

  #Technically, `` is call to Kernel#`
  #But we just need them in the call cache for speed
  def process_dxstr exp
    process exp.last if sexp? exp.last

    call = { :target => nil, :method => :`, :call => exp, :nested => false }

    if @current_template
      call[:location] = [:template, @current_template]
    else
      call[:location] = [:class, @current_class, @current_method]
    end

    @calls << call

    exp
  end

  #:"string" is equivalent to "string".to_sym
  def process_dsym exp
    exp.each { |arg| process arg if sexp? arg }

    call = { :target => nil, :method => :literal_to_sym, :call => exp, :nested => false }

    if @current_template
      call[:location] = [:template, @current_template]
    else
      call[:location] = [:class, @current_class, @current_method]
    end

    @calls << call

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
      when :ivar, :lvar, :const, :lit
        exp.value
      when :true, :false
        exp[0]
      when :colon2
        begin
          class_name exp
        rescue StandardError
          exp
        end
      when :self
        @current_class || @current_module || nil
      else
        exp
      end
    else
      exp
    end
  end

  #Returns method chain as an array
  #For example, User.human.alive.all would return [:User, :human, :alive, :all]
  def get_chain call
    if node_type? call, :call, :attrasgn
      get_chain(call.target) + [call.method]
    else
      [get_target(call)]
    end
  end
end
