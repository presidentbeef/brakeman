require 'sexp_processor'
require 'set'

#Looks for request parameters. Not used currently.
class Brakeman::ParamsProcessor < SexpProcessor
  attr_reader :result

  def initialize
    super()
    self.strict = false
    self.auto_shift_type = false
    self.require_empty = false
    self.default_method = :process_default
    self.warn_on_default = false
    @result = []
    @matched = false
    @mark = false
    @watch_nodes = Set[:call, :iasgn, :lasgn, :gasgn, :cvasgn, :return, :attrasgn]
    @params = Sexp.new(:call, nil, :params, Sexp.new(:arglist))
  end

  def process_default exp
    if @watch_nodes.include?(exp.node_type) and not @mark
      @mark = true
      @matched = false
      process_these exp[1..-1]
      if @matched
        @result << exp
        @matched = false
      end
      @mark = false
    else
      process_these exp[1..-1]
    end

    exp
  end

  def process_these exp
    exp.each do |e|
      if sexp? e and not e.empty?
        process e
      end
    end
  end

  def process_call exp
    if @mark
      actually_process_call exp
    else
      @mark = true
      actually_process_call exp
      if @matched
        @result << exp
      end
      @mark = @matched = false
    end
      
    exp
  end 

  def actually_process_call exp
    process exp[1]
    process exp[3]
    if exp[1] == @params or exp == @params
      @matched = true
    end
  end

  #Don't really care about condition
  def process_if exp
    process_these exp[2..-1]
    exp
  end

end
