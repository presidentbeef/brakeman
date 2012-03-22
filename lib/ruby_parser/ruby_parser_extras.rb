require 'stringio'
require 'racc/parser'
require 'sexp'
require 'strscan'

# WHY do I have to do this?!?
class Regexp
  ONCE = 0 unless defined? ONCE # FIX: remove this - it makes no sense

  unless defined? ENC_NONE then
    ENC_NONE = /x/n.options
    ENC_EUC  = /x/e.options
    ENC_SJIS = /x/s.options
    ENC_UTF8 = /x/u.options
  end
end

# I hate ruby 1.9 string changes
class Fixnum
  def ord
    self
  end
end unless "a"[0] == "a"

class RPStringScanner < StringScanner
#   if ENV['TALLY'] then
#     alias :old_getch :getch
#     def getch
#       warn({:getch => caller[0]}.inspect)
#       old_getch
#     end
#   end
  def current_line # HAHA fuck you (HACK)
    string[0..pos][/\A.*__LINE__/m].split(/\n/).size
  end

  def extra_lines_added
    @extra_lines_added ||= 0
  end

  def extra_lines_added= val
    @extra_lines_added = val
  end

  def lineno
    string[0...pos].count("\n") + 1 - extra_lines_added
  end

  # TODO: once we get rid of these, we can make things like
  # TODO: current_line and lineno much more accurate and easy to do

  def unread_many str # TODO: remove this entirely - we should not need it
    warn({:unread_many => caller[0]}.inspect) if ENV['TALLY']
    self.extra_lines_added += str.count("\n")
    string[pos, 0] = str
  end

  if ENV['DEBUG'] then
    alias :old_getch :getch
    def getch
      c = self.old_getch
      p :getch => [c, caller.first]
      c
    end

    alias :old_scan :scan
    def scan re
      s = old_scan re
      p :scan => [s, caller.first] if s
      s
    end
  end

  # TODO:
  # def last_line(src)
  #   if n = src.rindex("\n")
  #     src[(n+1) .. -1]
  #   else
  #     src
  #   end
  # end
  # private :last_line

  # def next_words_on_error
  #   if n = @src.rest.index("\n")
  #     @src.rest[0 .. (n-1)]
  #   else
  #     @src.rest
  #   end
  # end

  # def prev_words_on_error(ev)
  #   pre = @pre
  #   if ev and /#{Regexp.quote(ev)}$/ =~ pre
  #     pre = $`
  #   end
  #   last_line(pre)
  # end

  # def on_error(et, ev, values)
  #   lines_of_rest = @src.rest.to_a.length
  #   prev_words = prev_words_on_error(ev)
  #   at = 4 + prev_words.length
  #   message = <<-MSG
  # RD syntax error: line #{@blockp.line_index - lines_of_rest}:
  # ...#{prev_words} #{(ev||'')} #{next_words_on_error()} ...
  #   MSG
  #   message << " " * at + "^" * (ev ? ev.length : 0) + "\n"
  #   raise ParseError, message
  # end
end

module RubyParserStuff
  VERSION = '2.3.1' unless constants.include? "VERSION" # SIGH

  attr_accessor :lexer, :in_def, :in_single, :file
  attr_reader :env, :comments

  def arg_add(node1, node2) # TODO: nuke
    return s(:arglist, node2) unless node1

    node1[0] = :arglist if node1[0] == :array
    return node1 << node2 if node1[0] == :arglist

    return s(:arglist, node1, node2)
  end

  def arg_blk_pass node1, node2 # TODO: nuke
    node1 = s(:arglist, node1) unless [:arglist, :array].include? node1.first
    node1 << node2 if node2
    node1
  end

  def arg_concat node1, node2 # TODO: nuke
    raise "huh" unless node2
    node1 << s(:splat, node2).compact
    node1
  end

  def args arg, optarg, rest_arg, block_arg, post_arg = nil
    arg ||= s(:args)

    result = arg
    if optarg then
      optarg[1..-1].each do |lasgn| # FIX clean sexp iter
        raise "wtf? #{lasgn.inspect}" unless lasgn[0] == :lasgn
        result << lasgn[1]
      end
    end

    result << rest_arg  if rest_arg

    result << :"&#{block_arg.last}" if block_arg
    result << optarg    if optarg # TODO? huh - processed above as well
    post_arg[1..-1].each {|pa| result << pa } if post_arg

    result
  end

  def args19 vals # TODO: migrate to args once 1.8 tests pass as well
    result = s(:args)
    block  = nil

    vals.each do |val|
      case val
      when Sexp then
        case val.first
        when :args then
          val[1..-1].each do |name|
            result << name
          end
        when :block_arg then
          result << :"&#{val.last}"
        when :block then
         block = val
          val[1..-1].each do |lasgn| # FIX clean sexp iter
            raise "wtf? #{val.inspect}" unless lasgn[0] == :lasgn
            result << lasgn[1]
          end
        else
          raise "unhandled sexp: #{val.inspect}"
        end
      when Symbol then
        result << val
      when ",", nil then
        # ignore
      else
        raise "unhandled val: #{val.inspect} in #{vals.inspect}"
      end
    end

    result << block if block

    result
  end

  def aryset receiver, index
    index[0] = :arglist if index[0] == :array
    s(:attrasgn, receiver, :"[]=", index)
  end

  def assignable(lhs, value = nil)
    id = lhs.to_sym
    id = id.to_sym if Sexp === id

    raise SyntaxError, "Can't change the value of #{id}" if
      id.to_s =~ /^(?:self|nil|true|false|__LINE__|__FILE__)$/

    result = case id.to_s
             when /^@@/ then
               asgn = in_def || in_single > 0
               s((asgn ? :cvasgn : :cvdecl), id)
             when /^@/ then
               s(:iasgn, id)
             when /^\$/ then
               s(:gasgn, id)
             when /^[A-Z]/ then
               s(:cdecl, id)
             else
               case self.env[id]
               when :lvar then
                 s(:lasgn, id)
               when :dvar, nil then
                 if self.env.current[id] == :dvar then
                   s(:lasgn, id)
                 elsif self.env[id] == :dvar then
                   self.env.use(id)
                   s(:lasgn, id)
                 elsif ! self.env.dynamic? then
                   s(:lasgn, id)
                 else
                   s(:lasgn, id)
                 end
               else
                 raise "wtf? unknown type: #{self.env[id]}"
               end
             end

    self.env[id] ||= :lvar

    result << value if value

    return result
  end

  def block_append(head, tail)
    return head if tail.nil?
    return tail if head.nil?

    case head[0]
    when :lit, :str then
      return tail
    end

    line = [head.line, tail.line].compact.min

    head = remove_begin(head)
    head = s(:block, head) unless head.node_type == :block

    head.line = line
    head << tail
  end

  def cond node
    return nil if node.nil?
    node = value_expr node

    case node.first
    when :lit then
      if Regexp === node.last then
        return s(:match, node)
      else
        return node
      end
    when :and then
      return s(:and, cond(node[1]), cond(node[2]))
    when :or then
      return s(:or,  cond(node[1]), cond(node[2]))
    when :dot2 then
      label = "flip#{node.hash}"
      env[label] = :lvar
      return s(:flip2, node[1], node[2])
    when :dot3 then
      label = "flip#{node.hash}"
      env[label] = :lvar
      return s(:flip3, node[1], node[2])
    else
      return node
    end
  end

  ##
  # for pure ruby systems only

  def do_parse
    _racc_do_parse_rb(_racc_setup, false)
  end if ENV['PURE_RUBY']

  def get_match_node lhs, rhs # TODO: rename to new_match
    if lhs then
      case lhs[0]
      when :dregx, :dregx_once then
        return s(:match2, lhs, rhs).line(lhs.line)
      when :lit then
        return s(:match2, lhs, rhs).line(lhs.line) if Regexp === lhs.last
      end
    end

    if rhs then
      case rhs[0]
      when :dregx, :dregx_once then
        return s(:match3, rhs, lhs).line(lhs.line)
      when :lit then
        return s(:match3, rhs, lhs).line(lhs.line) if Regexp === rhs.last
      end
    end

    return s(:call, lhs, :"=~", s(:arglist, rhs)).line(lhs.line)
  end

  def gettable(id)
    id = id.to_sym if String === id

    result = case id.to_s
             when /^@@/ then
               s(:cvar, id)
             when /^@/ then
               s(:ivar, id)
             when /^\$/ then
               s(:gvar, id)
             when /^[A-Z]/ then
               s(:const, id)
             else
               type = env[id]
               if type then
                 s(type, id)
               elsif env.dynamic? and :dvar == env[id] then
                 s(:lvar, id)
               else
                 s(:call, nil, id, s(:arglist))
               end
             end

    raise "identifier #{id.inspect} is not valid" unless result

    result
  end

  ##
  # Canonicalize conditionals. Eg:
  #
  #   not x ? a : b
  #
  # becomes:
  #
  #   x ? b : a

  attr_accessor :canonicalize_conditions

  def initialize(options = {})
    super()

    v = self.class.name[/1[89]/]
    self.lexer = RubyLexer.new v && v.to_i
    self.lexer.parser = self
    @env = Environment.new
    @comments = []

    @canonicalize_conditions = true

    self.reset
  end

  def list_append list, item # TODO: nuke me *sigh*
    return s(:array, item) unless list
    list = s(:array, list) unless Sexp === list && list.first == :array
    list << item
  end

  def list_prepend item, list # TODO: nuke me *sigh*
    list = s(:array, list) unless Sexp === list && list[0] == :array
    list.insert 1, item
    list
  end

  def literal_concat head, tail
    return tail unless head
    return head unless tail

    htype, ttype = head[0], tail[0]

    head = s(:dstr, '', head) if htype == :evstr

    case ttype
    when :str then
      if htype == :str
        head[-1] << tail[-1]
      elsif htype == :dstr and head.size == 2 then
        head[-1] << tail[-1]
      else
        head << tail
      end
    when :dstr then
      if htype == :str then
        tail[1] = head[-1] + tail[1]
        head = tail
      else
        tail[0] = :array
        tail[1] = s(:str, tail[1])
        tail.delete_at 1 if tail[1] == s(:str, '')

        head.push(*tail[1..-1])
      end
    when :evstr then
      head[0] = :dstr if htype == :str
      if head.size == 2 and tail.size > 1 and tail[1][0] == :str then
        head[-1] << tail[1][-1]
        head[0] = :str if head.size == 2 # HACK ?
      else
        head.push(tail)
      end
    else
      x = [head, tail]
      raise "unknown type: #{x.inspect}"
    end

    return head
  end

  def logop(type, left, right) # TODO: rename logical_op
    left = value_expr left

    if left and left[0] == type and not left.paren then
      node, second = left, nil

      while (second = node[2]) && second[0] == type and not second.paren do
        node = second
      end

      node[2] = s(type, second, right)

      return left
    end

    return s(type, left, right)
  end

  def new_aref val
    val[2] ||= s(:arglist)
    val[2][0] = :arglist if val[2][0] == :array # REFACTOR
    if val[0].node_type == :self then
      result = new_call nil, :"[]", val[2]
    else
      result = new_call val[0], :"[]", val[2]
    end
    result
  end

  def new_body val
    result = val[0]

    if val[1] then
      result = s(:rescue)
      result << val[0] if val[0]

      resbody = val[1]

      while resbody do
        result << resbody
        resbody = resbody.resbody(true)
      end

      result << val[2] if val[2]

      result.line = (val[0] || val[1]).line
    elsif not val[2].nil? then
      warning("else without rescue is useless")
      result = block_append(result, val[2])
    end

    result = s(:ensure, result, val[3]).compact if val[3]
    return result
  end

  def new_call recv, meth, args = nil
    result = s(:call, recv, meth)
    result.line = recv.line if recv

    args ||= s(:arglist)
    args[0] = :arglist if args.first == :array
    args = s(:arglist, args) unless args.first == :arglist
    result << args
    result
  end

  def new_case expr, body
    result = s(:case, expr)
    line = (expr || body).line

    while body and body.node_type == :when
      result << body
      body = body.delete_at 3
    end

    # else
    body = nil if body == s(:block)
    result << body

    result.line = line
    result
  end

  def new_class val
    line, path, superclass, body = val[1], val[2], val[3], val[5]
    scope = s(:scope, body).compact
    result = s(:class, path, superclass, scope)
    result.line = line
    result.comments = self.comments.pop
    result
  end

  def new_compstmt val
    result = void_stmts(val[0])
    result = remove_begin(result) if result
    result
  end

  def new_defn val
    (_, line), name, args, body = val[0], val[1], val[3], val[4]
    body ||= s(:nil)

    body ||= s(:block)
    body = s(:block, body) unless body.first == :block

    result = s(:defn, name.to_sym, args, s(:scope, body))
    result.line = line
    result.comments = self.comments.pop
    result
  end

  def new_defs val
    recv, name, args, body = val[1], val[4], val[6], val[7]

    body ||= s(:block)
    body = s(:block, body) unless body.first == :block

    result = s(:defs, recv, name.to_sym, args, s(:scope, body))
    result.line = recv.line
    result.comments = self.comments.pop
    result
  end

  def new_for expr, var, body
    result = s(:for, expr, var).line(var.line)
    result << body if body
    result
  end

  def new_if c, t, f
    l = [c.line, t && t.line, f && f.line].compact.min
    c = cond c
    c, t, f = c.last, f, t if c[0] == :not and canonicalize_conditions
    s(:if, c, t, f).line(l)
  end

  def new_iter call, args, body
    result = s(:iter)
    result << call if call
    result << args
    result << body if body
    result
  end

  def new_masgn lhs, rhs, wrap = false
    rhs = value_expr(rhs)
    rhs = lhs[1] ? s(:to_ary, rhs) : s(:array, rhs) if wrap

    lhs.delete_at 1 if lhs[1].nil?
    lhs << rhs

    lhs
  end

  def new_module val
    line, path, body = val[1], val[2], val[4]
    body = s(:scope, body).compact
    result = s(:module, path, body)
    result.line = line
    result.comments = self.comments.pop
    result
  end

  def new_op_asgn val
    lhs, asgn_op, arg = val[0], val[1].to_sym, val[2]
    name = lhs.value
    arg = remove_begin(arg)
    result = case asgn_op # REFACTOR
             when :"||" then
               lhs << arg
               s(:op_asgn_or, self.gettable(name), lhs)
             when :"&&" then
               lhs << arg
               s(:op_asgn_and, self.gettable(name), lhs)
             else
               # TODO: why [2] ?
               lhs[2] = new_call(self.gettable(name), asgn_op,
                                 s(:arglist, arg))
               lhs
             end
    result.line = lhs.line
    result
  end

  def new_regexp val
    node = val[1] || s(:str, '')
    options = val[2]

    o, k = 0, nil
    options.split(//).uniq.each do |c| # FIX: this has a better home
      v = {
        'x' => Regexp::EXTENDED,
        'i' => Regexp::IGNORECASE,
        'm' => Regexp::MULTILINE,
        'o' => Regexp::ONCE,
        'n' => Regexp::ENC_NONE,
        'e' => Regexp::ENC_EUC,
        's' => Regexp::ENC_SJIS,
        'u' => Regexp::ENC_UTF8,
      }[c]
      raise "unknown regexp option: #{c}" unless v
      o += v
      k = c if c =~ /[esu]/
    end

    case node[0]
    when :str then
      node[0] = :lit
      node[1] = if k then
                  Regexp.new(node[1], o, k)
                else
                  Regexp.new(node[1], o)
                end
    when :dstr then
      if options =~ /o/ then
        node[0] = :dregx_once
      else
        node[0] = :dregx
      end
      node << o if o and o != 0
    else
      node = s(:dregx, '', node);
      node[0] = :dregx_once if options =~ /o/
      node << o if o and o != 0
    end

    node
  end

  def new_sclass val
    recv, in_def, in_single, body = val[3], val[4], val[6], val[7]
    scope = s(:scope, body).compact
    result = s(:sclass, recv, scope)
    result.line = val[2]
    self.in_def = in_def
    self.in_single = in_single
    result
  end

  def new_super args
    if args && args.node_type == :block_pass then
      s(:super, args)
    else
      args ||= s(:arglist)
      s(:super, *args[1..-1])
    end
  end

  def new_undef n, m = nil
    if m then
      block_append(n, s(:undef, m))
    else
      s(:undef, n)
    end
  end

  def new_until_or_while type, block, expr, pre
    other = type == :until ? :while : :until
    line = [block && block.line, expr.line].compact.min
    block, pre = block.last, false if block && block[0] == :begin

    expr = cond expr

    result = unless expr.first == :not and canonicalize_conditions then
               s(type,  expr,      block, pre)
             else
               s(other, expr.last, block, pre)
             end

    result.line = line
    result
  end

  def new_until block, expr, pre
    new_until_or_while :until, block, expr, pre
  end

  def new_while block, expr, pre
    new_until_or_while :while, block, expr, pre
  end

  def new_xstring str
    if str then
      case str[0]
      when :str
        str[0] = :xstr
      when :dstr
        str[0] = :dxstr
      else
        str = s(:dxstr, '', str)
      end
      str
    else
      s(:xstr, '')
    end
  end

  def new_yield args = nil
    # TODO: raise args.inspect unless [:arglist].include? args.first # HACK
    raise SyntaxError, "Block argument should not be given." if
      args && args.node_type == :block_pass

    args ||= s(:arglist)

    # TODO: I can prolly clean this up
    args[0] = :arglist       if args.first == :array
    args = s(:arglist, args) unless args.first == :arglist

    return s(:yield, *args[1..-1])
  end

  def next_token
    if self.lexer.advance then
      return self.lexer.token, self.lexer.yacc_value
    else
      return [false, '$end']
    end
  end

  def node_assign(lhs, rhs) # TODO: rename new_assign
    return nil unless lhs

    rhs = value_expr rhs

    case lhs[0]
    when :gasgn, :iasgn, :lasgn, :dasgn, :dasgn_curr,
      :masgn, :cdecl, :cvdecl, :cvasgn then
      lhs << rhs
    when :attrasgn, :call then
      args = lhs.pop unless Symbol === lhs.last
      lhs << arg_add(args, rhs)
    when :const then
      lhs[0] = :cdecl
      lhs << rhs
    else
      raise "unknown lhs #{lhs.inspect}"
    end

    lhs
  end

  def process(str, file = "(string)")
    raise "bad val: #{str.inspect}" unless String === str

    self.file = file
    self.lexer.src = str.dup

    @yydebug = ENV.has_key? 'DEBUG'

    do_parse
  end
  alias :parse :process

  def remove_begin node
    oldnode = node
    if node and :begin == node[0] and node.size == 2 then
      node = node[-1]
      node.line = oldnode.line
    end
    node
  end

  def reset
    lexer.reset
    self.in_def = false
    self.in_single = 0
    self.env.reset
    self.comments.clear
  end

  def ret_args node
    if node then
      raise SyntaxError, "block argument should not be given" if
        node[0] == :block_pass

      node = node.last if node[0] == :array && node.size == 2
      # HACK matz wraps ONE of the FOUR splats in a newline to
      # distinguish. I use paren for now. ugh
      node = s(:svalue, node) if node[0] == :splat and not node.paren
      node[0] = :svalue if node[0] == :arglist && node[1][0] == :splat
    end

    node
  end

  def s(*args)
    result = Sexp.new(*args)
    result.line ||= lexer.lineno if lexer.src          # otherwise...
    result.file = self.file
    result
  end

  def value_expr oldnode # HACK
    node = remove_begin oldnode
    node.line = oldnode.line if oldnode
    node[2] = value_expr(node[2]) if node and node[0] == :if
    node
  end

  def void_stmts node
    return nil unless node
    return node unless node[0] == :block

    node[1..-1] = node[1..-1].map { |n| remove_begin(n) }
    node
  end

  def warning s
    # do nothing for now
  end

  def yyerror msg
    # for now do nothing with the msg
    super
  end

  class Keyword
    class KWtable
      attr_accessor :name, :state, :id0, :id1
      def initialize(name, id=[], state=nil)
        @name  = name
        @id0, @id1 = id
        @state = state
      end
    end

    ##
    # :stopdoc:
    #
    # :expr_beg    = ignore newline, +/- is a sign.
    # :expr_end    = newline significant, +/- is a operator.
    # :expr_arg    = newline significant, +/- is a operator.
    # :expr_cmdarg = newline significant, +/- is a operator.
    # :expr_endarg = newline significant, +/- is a operator.
    # :expr_mid    = newline significant, +/- is a operator.
    # :expr_fname  = ignore newline, no reserved words.
    # :expr_dot    = right after . or ::, no reserved words.
    # :expr_class  = immediate after class, no here document.

    wordlist = [
                ["end",      [:kEND,      :kEND        ], :expr_end   ],
                ["else",     [:kELSE,     :kELSE       ], :expr_beg   ],
                ["case",     [:kCASE,     :kCASE       ], :expr_beg   ],
                ["ensure",   [:kENSURE,   :kENSURE     ], :expr_beg   ],
                ["module",   [:kMODULE,   :kMODULE     ], :expr_beg   ],
                ["elsif",    [:kELSIF,    :kELSIF      ], :expr_beg   ],
                ["def",      [:kDEF,      :kDEF        ], :expr_fname ],
                ["rescue",   [:kRESCUE,   :kRESCUE_MOD ], :expr_mid   ],
                ["not",      [:kNOT,      :kNOT        ], :expr_beg   ],
                ["then",     [:kTHEN,     :kTHEN       ], :expr_beg   ],
                ["yield",    [:kYIELD,    :kYIELD      ], :expr_arg   ],
                ["for",      [:kFOR,      :kFOR        ], :expr_beg   ],
                ["self",     [:kSELF,     :kSELF       ], :expr_end   ],
                ["false",    [:kFALSE,    :kFALSE      ], :expr_end   ],
                ["retry",    [:kRETRY,    :kRETRY      ], :expr_end   ],
                ["return",   [:kRETURN,   :kRETURN     ], :expr_mid   ],
                ["true",     [:kTRUE,     :kTRUE       ], :expr_end   ],
                ["if",       [:kIF,       :kIF_MOD     ], :expr_beg   ],
                ["defined?", [:kDEFINED,  :kDEFINED    ], :expr_arg   ],
                ["super",    [:kSUPER,    :kSUPER      ], :expr_arg   ],
                ["undef",    [:kUNDEF,    :kUNDEF      ], :expr_fname ],
                ["break",    [:kBREAK,    :kBREAK      ], :expr_mid   ],
                ["in",       [:kIN,       :kIN         ], :expr_beg   ],
                ["do",       [:kDO,       :kDO         ], :expr_beg   ],
                ["nil",      [:kNIL,      :kNIL        ], :expr_end   ],
                ["until",    [:kUNTIL,    :kUNTIL_MOD  ], :expr_beg   ],
                ["unless",   [:kUNLESS,   :kUNLESS_MOD ], :expr_beg   ],
                ["or",       [:kOR,       :kOR         ], :expr_beg   ],
                ["next",     [:kNEXT,     :kNEXT       ], :expr_mid   ],
                ["when",     [:kWHEN,     :kWHEN       ], :expr_beg   ],
                ["redo",     [:kREDO,     :kREDO       ], :expr_end   ],
                ["and",      [:kAND,      :kAND        ], :expr_beg   ],
                ["begin",    [:kBEGIN,    :kBEGIN      ], :expr_beg   ],
                ["__LINE__", [:k__LINE__, :k__LINE__   ], :expr_end   ],
                ["class",    [:kCLASS,    :kCLASS      ], :expr_class ],
                ["__FILE__", [:k__FILE__, :k__FILE__   ], :expr_end   ],
                ["END",      [:klEND,     :klEND       ], :expr_end   ],
                ["BEGIN",    [:klBEGIN,   :klBEGIN     ], :expr_end   ],
                ["while",    [:kWHILE,    :kWHILE_MOD  ], :expr_beg   ],
                ["alias",    [:kALIAS,    :kALIAS      ], :expr_fname ],
               ].map { |args| KWtable.new(*args) }

    # :startdoc:

    WORDLIST = Hash[*wordlist.map { |o| [o.name, o] }.flatten] unless
      defined? WORDLIST

    def self.keyword str
      WORDLIST[str]
    end
  end

  class Environment
    attr_reader :env, :dyn

    def [] k
      self.all[k]
    end

    def []= k, v
      raise "no" if v == true
      self.current[k] = v
    end

    def all
      idx = @dyn.index(false) || 0
      @env[0..idx].reverse.inject { |env, scope| env.merge scope }
    end

    def current
      @env.first
    end

    def dynamic
      idx = @dyn.index false
      @env[0...idx].reverse.inject { |env, scope| env.merge scope } || {}
    end

    def dynamic?
      @dyn[0] != false
    end

    def extend dyn = false
      @dyn.unshift dyn
      @env.unshift({})
      @use.unshift({})
    end

    def initialize dyn = false
      @dyn = []
      @env = []
      @use = []
      self.reset
    end

    def reset
      @dyn.clear
      @env.clear
      @use.clear
      self.extend
    end

    def unextend
      @dyn.shift
      @env.shift
      @use.shift
      raise "You went too far unextending env" if @env.empty?
    end

    def use id
      @env.each_with_index do |env, i|
        if env[id] then
          @use[i][id] = true
        end
      end
    end

    def used? id
      idx = @dyn.index false # REFACTOR
      u = @use[0...idx].reverse.inject { |env, scope| env.merge scope } || {}
      u[id]
    end
  end

  class StackState
    attr_reader :stack

    def initialize(name)
      @name = name
      @stack = [false]
    end

    def inspect
      "StackState(#{@name}, #{@stack.inspect})"
    end

    def is_in_state
      @stack.last
    end

    def lexpop
      raise if @stack.size == 0
      a = @stack.pop
      b = @stack.pop
      @stack.push(a || b)
    end

    def pop
      r = @stack.pop
      @stack.push false if @stack.size == 0
      r
    end

    def push val
      @stack.push val
    end
  end
end

class Ruby19Parser < Racc::Parser
  include RubyParserStuff
end

class Ruby18Parser < Racc::Parser
  include RubyParserStuff
end

class RubyParser < Ruby18Parser
  def initialize
    super
    warn "WA\RNING: Deprecated: RubyParser. Use Ruby18Parser or Ruby19Parser"
    warn "  from #{caller.first}"
  end
end

############################################################
# HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK

class Symbol
  def is_argument # TODO: phase this out
    return self == :expr_arg || self == :expr_cmdarg
  end
end

require 'bm_sexp'

# END HACK
############################################################
