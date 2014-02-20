##
# SexpProcessor provides a uniform interface to process Sexps.
#
# In order to create your own SexpProcessor subclass you'll need
# to call super in the initialize method, then set any of the
# Sexp flags you want to be different from the defaults.
#
# SexpProcessor uses a Sexp's type to determine which process method
# to call in the subclass.  For Sexp <code>s(:lit, 1)</code>
# SexpProcessor will call #process_lit, if it is defined.
#

class Brakeman::SexpProcessor

  VERSION = 'CUSTOM'

  ##
  # Return a stack of contexts. Most recent node is first.

  attr_reader :context

  ##
  # Expected result class

  attr_accessor :expected

  ##
  # A scoped environment to make you happy.

  attr_reader :env

  ##
  # Creates a new SexpProcessor.  Use super to invoke this
  # initializer from SexpProcessor subclasses, then use the
  # attributes above to customize the functionality of the
  # SexpProcessor

  def initialize
    @expected            = Sexp

    # we do this on an instance basis so we can subclass it for
    # different processors.
    @processors = {}
    @context    = []

    public_methods.each do |name|
      if name.to_s.start_with? "process_" then
        @processors[name[8..-1].to_sym] = name.to_sym
      end
    end
  end

  ##
  # Default Sexp processor.  Invokes process_<type> methods matching
  # the Sexp type given.  Performs additional checks as specified by
  # the initializer.

  def process(exp)
    return nil if exp.nil?

    result = nil

    type = exp.first
    raise "Type should be a Symbol, not: #{exp.first.inspect} in #{exp.inspect}" unless Symbol === type

    in_context type do
      # now do a pass with the real processor (or generic)
      meth = @processors[type]
      if meth then
        if $DEBUG
          result = error_handler(type) do
            self.send(meth, exp)
          end
        else
          result = self.send(meth, exp)
        end

      else
        result = self.process_default(exp)
      end
    end
    
    raise SexpTypeError, "Result must be a #{@expected}, was #{result.class}:#{result.inspect}" unless @expected === result
    
    result
  end

  def error_handler(type, exp=nil) # :nodoc:
    begin
      return yield
    rescue => err
      warn "#{err.class} Exception thrown while processing #{type} for sexp #{exp.inspect} #{caller.inspect}" if $DEBUG
      raise
    end
  end

  ##
  # A fairly generic processor for a dummy node. Dummy nodes are used
  # when your processor is doing a complicated rewrite that replaces
  # the current sexp with multiple sexps.
  #
  # Bogus Example:
  #
  #   def process_something(exp)
  #     return s(:dummy, process(exp), s(:extra, 42))
  #   end

  def process_dummy(exp)
    result = @expected.new(:dummy) rescue @expected.new

    until exp.empty? do
      result << self.process(exp.shift)
    end

    result
  end

  ##
  # Add a scope level to the current env. Eg:
  #
  #   def process_defn exp
  #     name = exp.shift
  #     args = process(exp.shift)
  #     scope do
  #       body = process(exp.shift)
  #       # ...
  #     end
  #   end
  #
  #   env[:x] = 42
  #   scope do
  #     env[:x]       # => 42
  #     env[:y] = 24
  #   end
  #   env[:y]         # => nil

  def scope &block
    env.scope(&block)
  end

  def in_context type
    self.context.unshift type

    yield

    self.context.shift
  end

  ##
  # I really hate this here, but I hate subdirs in my lib dir more...
  # I guess it is kinda like shaving... I'll split this out when it
  # itches too much...

  class Environment
    def initialize
      @env = []
      @env.unshift({})
    end

    def all
      @env.reverse.inject { |env, scope| env.merge scope }
    end

    def depth
      @env.length
    end

    # TODO: depth_of

    def [] name
      hash = @env.find { |closure| closure.has_key? name }
      hash[name] if hash
    end

    def []= name, val
      hash = @env.find { |closure| closure.has_key? name } || @env.first
      hash[name] = val
    end

    def scope
      @env.unshift({})
      begin
        yield
      ensure
        @env.shift
        raise "You went too far unextending env" if @env.empty?
      end
    end
  end
end

class Object

  ##
  # deep_clone is the usual Marshalling hack to make a deep copy.
  # It is rather slow, so use it sparingly. Helps with debugging
  # SexpProcessors since you usually shift off sexps.

  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

##
# SexpProcessor base exception class.

class SexpProcessorError < StandardError; end

##
# Raised by SexpProcessor if it sees a node type listed in its
# unsupported list.

class UnsupportedNodeError < SexpProcessorError; end

##
# Raised by SexpProcessor if it is in strict mode and sees a node for
# which there is no processor available.

class UnknownNodeError < SexpProcessorError; end

##
# Raised by SexpProcessor if a processor did not process every node in
# a sexp and @require_empty is true.

class NotEmptyError < SexpProcessorError; end

##
# Raised if assert_type encounters an unexpected sexp type.

class SexpTypeError < SexpProcessorError; end
