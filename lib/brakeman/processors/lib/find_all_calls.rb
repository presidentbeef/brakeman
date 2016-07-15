require 'brakeman/processors/lib/basic_processor'

class Brakeman::FindAllCalls < Brakeman::BasicProcessor
  attr_reader :calls

  def initialize tracker
    super
    @current_class = nil
    @current_method = nil
    @in_target = false
    @calls = []
    @cache = {}
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
  def process_defn exp
    return exp unless @current_method
    process_all exp.body
  end

  alias process_defs process_defn

  #Process body of block
  def process_rlist exp
    process_all exp
  end

  def process_call exp
    @calls << create_call_hash(exp)
    exp
  end

  def process_iter exp
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

  #Calls to render() are converted to s(:render, ...) but we would
  #like them in the call cache still for speed
  def process_render exp
    process exp.last if sexp? exp.last

    add_simple_call :render, exp

    exp
  end

  #Technically, `` is call to Kernel#`
  #But we just need them in the call cache for speed
  def process_dxstr exp
    process exp.last if sexp? exp.last

    add_simple_call :`, exp

    exp
  end

  #:"string" is equivalent to "string".to_sym
  def process_dsym exp
    exp.each { |arg| process arg if sexp? arg }

    add_simple_call :literal_to_sym, exp

    exp
  end

  # Process a dynamic regex like a call
  def process_dregx exp
    exp.each { |arg| process arg if sexp? arg }

    add_simple_call :brakeman_regex_interp, exp

    exp
  end

  #Process an assignment like a call
  def process_attrasgn exp
    process_call exp
  end

  private

  def add_simple_call method_name, exp
    @calls << { :target => nil,
                :method => method_name,
                :call => exp,
                :nested => false,
                :location => make_location }
  end

  #Gets the target of a call as a Symbol
  #if possible
  def get_target exp, include_calls = false
    if sexp? exp
      case exp.node_type
      when :ivar, :lvar, :const, :lit
        exp.value
      when :true, :false
        exp[0]
      when :colon2
        class_name exp
      when :self
        @current_class || @current_module || nil
      when :params, :session, :cookies
        exp.node_type
      when :call, :safe_call
        if include_calls
          if exp.target.nil?
            exp.method
          else
            t = get_target(exp.target, :include_calls)
            if t.is_a? Symbol
              :"#{t}.#{exp.method}"
            else
              exp
            end
          end
        else
          exp
        end
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
    if node_type? call, :call, :attrasgn, :safe_call, :safe_attrasgn
      get_chain(call.target) + [call.method]
    elsif call.nil?
      []
    else
      [get_target(call)]
    end
  end

  def make_location
    if @current_template
      key = [@current_template, @current_file]
      cached = @cache[key]
      return cached if cached

      @cache[key] = { :type => :template,
        :template => @current_template,
        :file => @current_file }
    else
      key = [@current_class, @current_method, @current_file]
      cached = @cache[key]
      return cached if cached
      @cache[key] = { :type => :class,
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

      target = get_target(target, :include_calls)
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
