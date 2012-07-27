#Sexp changes from ruby_parser
#and some changes for caching hash value and tracking 'original' line number
#of a Sexp.
class Sexp
  attr_reader :paren
  ASSIGNMENT_BOOL = [:gasgn, :iasgn, :lasgn, :cvdecl, :cdecl, :or, :and]

  def paren
    @paren ||= false
  end

  def value
    raise "multi item sexp" if size > 2
    last
  end

  def second
    self[1]
  end

  def to_sym
    self.value.to_sym
  end

  def node_type= type
    self[0] = type
  end

  alias :node_type :sexp_type
  alias :values :sexp_body # TODO: retire

  alias :old_push :<<
  alias :old_line :line
  alias :old_line_set :line=
  alias :old_file_set :file=
  alias :old_comments_set :comments=
  alias :old_compact :compact
  alias :old_fara :find_and_replace_all
  alias :old_find_node :find_node

  def original_line line = nil
    if line
      @my_hash_value = nil
      @original_line = line
      self
    else
      @original_line ||= nil
    end
  end

  def hash
    #There still seems to be some instances in which the hash of the
    #Sexp changes, but I have not found what method call is doing it.
    #Of course, Sexp is subclasses from Array, so who knows what might
    #be going on.
    @my_hash_value ||= super
  end

  def line num = nil
    @my_hash_value = nil if num
    old_line(num)
  end

  def line= *args
    @my_hash_value = nil
    old_line_set(*args)
  end

  def file= *args
    @my_hash_value = nil
    old_file_set(*args)
  end

  def compact
    @my_hash_value = nil
    old_compact
  end

  def find_and_replace_all *args
    @my_hash_value = nil
    old_fara(*args)
  end

  def find_node *args
    @my_hash_value = nil
    old_find_node(*args)
  end

  def paren= arg
    @my_hash_value = nil
    @paren = arg
  end

  def comments= *args
    @my_hash_value = nil
    old_comments_set(*args)
  end

  def each_sexp
    self.each do |e|
      yield e if Sexp === e
    end
  end

  def expect *types
    unless types.include? self.node_type
      raise WrongSexpError, "Expected #{types.join ' or '} but given #{self.inspect}", caller[1..-1]
    end
  end

  #Returns target of a method call
  #
  #s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1)))
  #         ^-----------target-----------^
  def target
    expect :call, :attrasgn
    self[1]
  end

  def target= exp
    expect :call, :attrasgn
    self[1] = exp
  end

  #Returns method of a method call
  #
  #s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1)))
  #                        ^- method
  def method
    expect :call, :attrasgn
    self[2]
  end

  def arglist= exp
    expect :call
    self[3] = exp
    #RP 3 TODO
  end

  #Returns arglist for method call. This differs from Sexp#args, as Sexp#args
  #does not return a 'real' Sexp (it does not have a node type) but
  #Sexp#arglist returns a s(:arglist, ...)
  def arglist
    expect :call, :attrasgn
    self[3]

    #For new ruby_parser
    #Sexp.new(:arglist, *self[3..-1])
  end

  #Returns argument list of a method call
  #
  #s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1)))
  #                                                         ^--args--^
  def args
    expect :call, :attrasgn
    #For new ruby_parser
    #if self[3]
    #  self[3..-1]
    #else
    #  []
    #end

    #For old ruby_parser
    if self[3]
      self[3][1..-1]
    else
      []
    end
  end

  def condition
    expect :if
    self[1]
  end

  def then_clause
    expect :if
    self[2]
  end

  def else_clause
    expect :if
    self[3]
  end

  #Method call associated with a block
  #
  #s(:iter,
  # s(:call, nil, :x, s(:arglist)), <- block_call
  #  s(:lasgn, :y),
  #   s(:block, s(:lvar, :y), s(:call, nil, :z, s(:arglist))))
  def block_call
    expect :iter, :call_with_block
    self[1]
  end

  #Block of a call with a block.
  #Could be a single expression or a block
  #
  #s(:iter,
  # s(:call, nil, :x, s(:arglist)),
  #  s(:lasgn, :y),
  #   s(:block, s(:lvar, :y), s(:call, nil, :z, s(:arglist))))
  #   ^-------------------- block --------------------------^
  def block
    expect :iter, :call_with_block
    self[3]
  end

  #Returns parameters for a block
  #
  #s(:iter,
  # s(:call, nil, :x, s(:arglist)),
  #  s(:lasgn, :y), <- block_args
  #   s(:call, nil, :p, s(:arglist, s(:lvar, :y))))
  def block_args
    expect :iter, :call_with_block
    self[2]
  end

  #Returns left side (variable) of assignment:
  #
  #s(:lasgn, :x, s(:lit, 1))
  #           ^--lhs
  def lhs= exp
    expect *ASSIGNMENT_BOOL
    self[1] = exp
  end

  def lhs
    expect *ASSIGNMENT_BOOL
    self[1]
  end

  def rhs= exp
    expect *ASSIGNMENT_BOOL
    self[2] = exp
  end

  
  #Returns right side (value) of assignment:
  #
  #s(:lasgn, :x, s(:lit, 1))
  #              ^--rhs---^
  def rhs
    expect *ASSIGNMENT_BOOL
    self[2]
  end

  def meth_name
    expect :defn, :defs, :methdef, :selfdef

    case self.node_type
    when :defn, :methdef
      self[1]
    when :defs, :selfdef
      self[2]
    end
  end

  def body= exp
    expect :defn, :defs, :methdef, :selfdef, :class, :module
    
    case self.node_type
    when :defn, :methdef, :class
      self[3] = exp
    when :defs, :selfdef
      self[4] = exp
    when :module
      self[2] = exp
    end
  end

  #Returns body of a method definition:
  #
  #s(:defn,
  # :x,
  #  s(:args, :y),
  #   s(:scope, s(:block, s(:call, nil, :z, s(:arglist))))) <-body
  def body
    expect :defn, :defs, :methdef, :selfdef, :class, :module

    case self.node_type
    when :defn, :methdef, :class
      self[3]
    when :defs, :selfdef
      self[4]
    when :module
      self[2]
    end
  end

  def render_type
    expect :render
    self[1]
  end

  def class_name
    expect :class, :module
    self[1]
  end

  def parent_name
    expect :class
    self[2]
  end
end

#Invalidate hash cache if the Sexp changes
[:[]=, :clear, :collect!, :compact!, :concat, :delete, :delete_at,
  :delete_if, :drop, :drop_while, :fill, :flatten!, :replace, :insert,
  :keep_if, :map!, :pop, :push, :reject!, :replace, :reverse!, :rotate!,
  :select!, :shift, :shuffle!, :slice!, :sort!, :sort_by!, :transpose, 
  :uniq!, :unshift].each do |method|

  Sexp.class_eval <<-RUBY
    def #{method} *args
      @my_hash_value = nil
      super
    end
    RUBY
end

class WrongSexpError < RuntimeError; end
