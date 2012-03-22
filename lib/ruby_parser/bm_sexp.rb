#Sexp changes from ruby_parser
#and some changes for caching hash value and tracking 'original' line number
#of a Sexp.
class Sexp
  attr_reader :paren

  def paren
    @paren ||= false
  end

  def value
    raise "multi item sexp" if size > 2
    last
  end

  def to_sym
    self.value.to_sym
  end

  alias :node_type :sexp_type
  alias :values :sexp_body # TODO: retire

  alias :old_init :initialize
  alias :old_push :<<
  alias :old_line :line
  alias :old_line_set :line=
  alias :old_file_set :file=
  alias :old_comments_set :comments=
  alias :old_compact :compact
  alias :old_fara :find_and_replace_all
  alias :old_find_node :find_node

  def initialize *args
    old_init *args
    @original_line = nil
    @my_hash_value = nil
  end

  def original_line line = nil
    if line
      @my_hash_value = nil
      @original_line = line
    else
      @original_line
    end
  end

  def hash
    #There still seems to be some instances in which the hash of the
    #Sexp changes, but I have not found what method call is doing it.
    #Of course, Sexp is subclasses from Array, so who knows what might
    #be going on.
    @my_hash_value ||= super
  end

  def line *args
    @my_hash_value = nil
    old_line *args
  end

  def line= *args
    @my_hash_value = nil
    old_line_set *args
  end

  def file= *args
    @my_hash_value = nil
    old_file_set *args
  end

  def compact
    @my_hash_value = nil
    old_compact
  end

  def find_and_replace_all *args
    @my_hash_value = nil
    old_fara *args
  end

  def find_node *args
    @my_hash_value = nil
    old_find_node *args
  end

  def paren= arg
    @my_hash_value = nil
    @paren = arg
  end

  def comments= *args
    @my_hash_value = nil
    old_comments_set *args
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


