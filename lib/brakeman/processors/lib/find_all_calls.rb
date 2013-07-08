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
  def process_source exp, opts
    @current_class = opts[:class]
    @current_method = opts[:method]
    @current_template = opts[:template]
    @current_file = opts[:file]
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
    @calls << create_call_hash(exp)
    exp
  end

  def process_call_with_block exp
    call = exp.block_call

    if call.node_type == :call
      call_hash = create_call_hash(call)

      call_hash[:block] = exp.block
      call_hash[:block_args] = exp.block_args

      @calls << call_hash

      process exp.block
    else
      #Probably a :render call with block
      process call
      process exp.block
    end

    exp
  end

  alias process_iter process_call_with_block

  #Calls to render() are converted to s(:render, ...) but we would
  #like them in the call cache still for speed
  def process_render exp
    process exp.last if sexp? exp.last

    @calls << { :target => nil,
                :method => :render,
                :call => exp,
                :nested => false,
                :location => make_location }

    exp
  end

  #Technically, `` is call to Kernel#`
  #But we just need them in the call cache for speed
  def process_dxstr exp
    process exp.last if sexp? exp.last

    @calls << { :target => nil,
                :method => :`,
                :call => exp,
                :nested => false,
                :location => make_location }

    exp
  end

  #:"string" is equivalent to "string".to_sym
  def process_dsym exp
    exp.each { |arg| process arg if sexp? arg }

    @calls << { :target => nil,
                :method => :literal_to_sym,
                :call => exp,
                :nested => false,
                :location => make_location }

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

  def make_location
    if @current_template
      { :type => :template,
        :template => @current_template,
        :file => @current_file }
    else
      { :type => :class,
        :class => @current_class,
        :method => @current_method,
        :file => @current_file }
    end

  end

  #Return info hash for a call Sexp
  def create_call_hash exp
    target = get_target exp.target

    if call? target
      already_in_target = @in_target
      @in_target = true
      process target
      @in_target = already_in_target
    end

    method = exp.method
    process_call_args exp

    { :target => target,
      :method => method,
      :call => exp,
      :nested => @in_target,
      :chain => get_chain(exp),
      :location => make_location }
  end
end
