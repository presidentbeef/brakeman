class RubyLexer
  attr_accessor :command_start
  attr_accessor :cmdarg
  attr_accessor :cond
  attr_accessor :nest

  ESC_RE = /\\([0-7]{1,3}|x[0-9a-fA-F]{1,2}|M-[^\\]|(C-|c)[^\\]|[^0-7xMCc])/

  # Additional context surrounding tokens that both the lexer and
  # grammar use.
  attr_reader :lex_state

  attr_accessor :lex_strterm

  attr_accessor :parser # HACK for very end of lexer... *sigh*

  # Stream of data that yylex examines.
  attr_reader :src

  # Last token read via yylex.
  attr_accessor :token

  attr_accessor :string_buffer

  # Value of last token which had a value associated with it.
  attr_accessor :yacc_value

  # What handles warnings
  attr_accessor :warnings

  EOF = :eof_haha!

  # ruby constants for strings (should this be moved somewhere else?)
  STR_FUNC_BORING = 0x00
  STR_FUNC_ESCAPE = 0x01 # TODO: remove and replace with REGEXP
  STR_FUNC_EXPAND = 0x02
  STR_FUNC_REGEXP = 0x04
  STR_FUNC_AWORDS = 0x08
  STR_FUNC_SYMBOL = 0x10
  STR_FUNC_INDENT = 0x20 # <<-HEREDOC

  STR_SQUOTE = STR_FUNC_BORING
  STR_DQUOTE = STR_FUNC_BORING | STR_FUNC_EXPAND
  STR_XQUOTE = STR_FUNC_BORING | STR_FUNC_EXPAND
  STR_REGEXP = STR_FUNC_REGEXP | STR_FUNC_ESCAPE | STR_FUNC_EXPAND
  STR_SSYM   = STR_FUNC_SYMBOL
  STR_DSYM   = STR_FUNC_SYMBOL | STR_FUNC_EXPAND

  TOKENS = {
    "!"   => :tBANG,
    "!="  => :tNEQ,
    "!~"  => :tNMATCH,
    ","   => :tCOMMA,
    ".."  => :tDOT2,
    "..." => :tDOT3,
    "="   => :tEQL,
    "=="  => :tEQ,
    "===" => :tEQQ,
    "=>"  => :tASSOC,
    "=~"  => :tMATCH,
  }

  # How the parser advances to the next token.
  #
  # @return true if not at end of file (EOF).

  def advance
    r = yylex
    self.token = r

    raise "yylex returned nil" unless r

    return RubyLexer::EOF != r
  end

  def arg_ambiguous
    self.warning("Ambiguous first argument. make sure.")
  end

  def comments
    c = @comments.join
    @comments.clear
    c
  end

  def expr_beg_push val
    cond.push false
    cmdarg.push false
    self.lex_state = :expr_beg
    self.yacc_value = val
  end

  def fix_arg_lex_state
    self.lex_state = if lex_state == :expr_fname || lex_state == :expr_dot
                       :expr_arg
                     else
                       :expr_beg
                     end
  end

  def heredoc here # 63 lines
    _, eos, func, last_line = here

    indent  = (func & STR_FUNC_INDENT) != 0
    expand  = (func & STR_FUNC_EXPAND) != 0
    eos_re  = indent ? /[ \t]*#{eos}(\r?\n|\z)/ : /#{eos}(\r?\n|\z)/
    err_msg = "can't match #{eos_re.inspect} anywhere in "

    rb_compile_error err_msg if
      src.eos?

    if src.beginning_of_line? && src.scan(eos_re) then
      src.unread_many last_line # TODO: figure out how to remove this
      self.yacc_value = eos
      return :tSTRING_END
    end

    self.string_buffer = []

    if expand then
      case
      when src.scan(/#[$@]/) then
        src.pos -= 1 # FIX omg stupid
        self.yacc_value = src.matched
        return :tSTRING_DVAR
      when src.scan(/#[{]/) then
        self.yacc_value = src.matched
        return :tSTRING_DBEG
      when src.scan(/#/) then
        string_buffer << '#'
      end

      until src.scan(eos_re) do
        c = tokadd_string func, "\n", nil

        rb_compile_error err_msg if
          c == RubyLexer::EOF

        if c != "\n" then
          self.yacc_value = string_buffer.join.delete("\r")
          return :tSTRING_CONTENT
        else
          string_buffer << src.scan(/\n/)
        end

        rb_compile_error err_msg if
          src.eos?
      end

      # tack on a NL after the heredoc token - FIX NL should not be needed
      src.unread_many(eos + "\n") # TODO: remove this... stupid stupid stupid
    else
      until src.check(eos_re) do
        string_buffer << src.scan(/.*(\n|\z)/)
        rb_compile_error err_msg if
          src.eos?
      end
    end

    self.lex_strterm = [:heredoc, eos, func, last_line]
    self.yacc_value = string_buffer.join.delete("\r")

    return :tSTRING_CONTENT
  end

  def heredoc_identifier # 51 lines
    term, func = nil, STR_FUNC_BORING
    self.string_buffer = []

    case
    when src.scan(/(-?)(['"`])(.*?)\2/) then
      term = src[2]
      unless src[1].empty? then
        func |= STR_FUNC_INDENT
      end
      func |= case term
              when "\'" then
                STR_SQUOTE
              when '"' then
                STR_DQUOTE
              else
                STR_XQUOTE
              end
      string_buffer << src[3]
    when src.scan(/-?(['"`])(?!\1*\Z)/) then
      rb_compile_error "unterminated here document identifier"
    when src.scan(/(-?)(\w+)/) then
      term = '"'
      func |= STR_DQUOTE
      unless src[1].empty? then
        func |= STR_FUNC_INDENT
      end
      string_buffer << src[2]
    else
      return nil
    end

    if src.check(/.*\n/) then
      # TODO: think about storing off the char range instead
      line = src.string[src.pos, src.matched_size]
      src.string[src.pos, src.matched_size] = "\n"
      src.extra_lines_added += 1
      src.pos += 1
    else
      line = nil
    end

    self.lex_strterm = [:heredoc, string_buffer.join, func, line]

    if term == '`' then
      self.yacc_value = "`"
      return :tXSTRING_BEG
    else
      self.yacc_value = "\""
      return :tSTRING_BEG
    end
  end

  def initialize
    self.cond = RubyParser::StackState.new(:cond)
    self.cmdarg = RubyParser::StackState.new(:cmdarg)
    self.nest = 0
    @comments = []

    reset
  end

  def int_with_base base
    rb_compile_error "Invalid numeric format" if src.matched =~ /__/
    self.yacc_value = src.matched.to_i(base)
    return :tINTEGER
  end

  def lex_state= o
    raise "wtf\?" unless Symbol === o
    @lex_state = o
  end

  attr_writer :lineno
  def lineno
    @lineno ||= src.lineno
  end

  ##
  #  Parse a number from the input stream.
  #
  # @param c The first character of the number.
  # @return A int constant wich represents a token.

  def parse_number
    self.lex_state = :expr_end

    case
    when src.scan(/[+-]?0[xbd]\b/) then
      rb_compile_error "Invalid numeric format"
    when src.scan(/[+-]?0x[a-f0-9_]+/i) then
      int_with_base(16)
    when src.scan(/[+-]?0b[01_]+/) then
      int_with_base(2)
    when src.scan(/[+-]?0d[0-9_]+/) then
      int_with_base(10)
    when src.scan(/[+-]?0[Oo]?[0-7_]*[89]/) then
      rb_compile_error "Illegal octal digit."
    when src.scan(/[+-]?0[Oo]?[0-7_]+|0[Oo]/) then
      int_with_base(8)
    when src.scan(/[+-]?[\d_]+_(e|\.)/) then
      rb_compile_error "Trailing '_' in number."
    when src.scan(/[+-]?[\d_]+\.[\d_]+(e[+-]?[\d_]+)?\b|[+-]?[\d_]+e[+-]?[\d_]+\b/i) then
      number = src.matched
      if number =~ /__/ then
        rb_compile_error "Invalid numeric format"
      end
      self.yacc_value = number.to_f
      :tFLOAT
    when src.scan(/[+-]?0\b/) then
      int_with_base(10)
    when src.scan(/[+-]?[\d_]+\b/) then
      int_with_base(10)
    else
      rb_compile_error "Bad number format"
    end
  end

  def parse_quote # 58 lines
    beg, nnd, short_hand, c = nil, nil, false, nil

    if src.scan(/[a-z0-9]{1,2}/i) then # Long-hand (e.g. %Q{}).
      rb_compile_error "unknown type of %string" if src.matched_size == 2
      c, beg, short_hand = src.matched, src.getch, false
    else                               # Short-hand (e.g. %{, %., %!, etc)
      c, beg, short_hand = 'Q', src.getch, true
    end

    if src.eos? or c == RubyLexer::EOF or beg == RubyLexer::EOF then
      rb_compile_error "unterminated quoted string meets end of file"
    end

    # Figure nnd-char.  "\0" is special to indicate beg=nnd and that no nesting?
    nnd = { "(" => ")", "[" => "]", "{" => "}", "<" => ">" }[beg]
    nnd, beg = beg, "\0" if nnd.nil?

    token_type, self.yacc_value = nil, "%#{c}#{beg}"
    token_type, string_type = case c
                              when 'Q' then
                                ch = short_hand ? nnd : c + beg
                                self.yacc_value = "%#{ch}"
                                [:tSTRING_BEG,   STR_DQUOTE]
                              when 'q' then
                                [:tSTRING_BEG,   STR_SQUOTE]
                              when 'W' then
                                src.scan(/\s*/)
                                [:tWORDS_BEG,    STR_DQUOTE | STR_FUNC_AWORDS]
                              when 'w' then
                                src.scan(/\s*/)
                                [:tAWORDS_BEG,   STR_SQUOTE | STR_FUNC_AWORDS]
                              when 'x' then
                                [:tXSTRING_BEG,  STR_XQUOTE]
                              when 'r' then
                                [:tREGEXP_BEG,   STR_REGEXP]
                              when 's' then
                                self.lex_state  = :expr_fname
                                [:tSYMBEG,       STR_SSYM]
                              end

    rb_compile_error "Bad %string type. Expected [Qqwxr\W], found '#{c}'." if
      token_type.nil?

    self.lex_strterm = [:strterm, string_type, nnd, beg]

    return token_type
  end

  def parse_string(quote) # 65 lines
    _, string_type, term, open = quote

    space = false # FIX: remove these
    func = string_type
    paren = open
    term_re = Regexp.escape term

    awords = (func & STR_FUNC_AWORDS) != 0
    regexp = (func & STR_FUNC_REGEXP) != 0
    expand = (func & STR_FUNC_EXPAND) != 0

    unless func then # FIX: impossible, prolly needs == 0
      self.lineno = nil
      return :tSTRING_END
    end

    space = true if awords and src.scan(/\s+/)

    if self.nest == 0 && src.scan(/#{term_re}/) then
      if awords then
        quote[1] = nil
        return :tSPACE
      elsif regexp then
        self.yacc_value = self.regx_options
        self.lineno = nil
        return :tREGEXP_END
      else
        self.yacc_value = term
        self.lineno = nil
        return :tSTRING_END
      end
    end

    if space then
      return :tSPACE
    end

    self.string_buffer = []

    if expand
      case
      when src.scan(/#(?=[$@])/) then
        return :tSTRING_DVAR
      when src.scan(/#[{]/) then
        return :tSTRING_DBEG
      when src.scan(/#/) then
        string_buffer << '#'
      end
    end

    if tokadd_string(func, term, paren) == RubyLexer::EOF then
      rb_compile_error "unterminated string meets end of file"
    end

    self.yacc_value = string_buffer.join

    return :tSTRING_CONTENT
  end

  def rb_compile_error msg
    msg += ". near line #{self.lineno}: #{src.rest[/^.*/].inspect}"
    raise SyntaxError, msg
  end

  def read_escape # 51 lines
    case
    when src.scan(/\\/) then                  # Backslash
      '\\'
    when src.scan(/n/) then                   # newline
      "\n"
    when src.scan(/t/) then                   # horizontal tab
      "\t"
    when src.scan(/r/) then                   # carriage-return
      "\r"
    when src.scan(/f/) then                   # form-feed
      "\f"
    when src.scan(/v/) then                   # vertical tab
      "\13"
    when src.scan(/a/) then                   # alarm(bell)
      "\007"
    when src.scan(/e/) then                   # escape
      "\033"
    when src.scan(/b/) then                   # backspace
      "\010"
    when src.scan(/s/) then                   # space
      " "
    when src.scan(/[0-7]{1,3}/) then          # octal constant
      src.matched.to_i(8).chr
    when src.scan(/x([0-9a-fA-F]{1,2})/) then # hex constant
      src[1].to_i(16).chr
    when src.check(/M-\\[\\MCc]/) then
      src.scan(/M-\\/) # eat it
      c = self.read_escape
      c[0] = (c[0].ord | 0x80).chr
      c
    when src.scan(/M-(.)/) then
      c = src[1]
      c[0] = (c[0].ord | 0x80).chr
      c
    when src.check(/(C-|c)\\[\\MCc]/) then
      src.scan(/(C-|c)\\/) # eat it
      c = self.read_escape
      c[0] = (c[0].ord & 0x9f).chr
      c
    when src.scan(/C-\?|c\?/) then
      127.chr
    when src.scan(/(C-|c)(.)/) then
      c = src[2]
      c[0] = (c[0].ord & 0x9f).chr
      c
    when src.scan(/[McCx0-9]/) || src.eos? then
      rb_compile_error("Invalid escape character syntax")
    else
      src.getch
    end
  end

  def regx_options # 15 lines
    good, bad = [], []

    if src.scan(/[a-z]+/) then
      good, bad = src.matched.split(//).partition { |s| s =~ /^[ixmonesu]$/ }
    end

    unless bad.empty? then
      rb_compile_error("unknown regexp option%s - %s" %
                       [(bad.size > 1 ? "s" : ""), bad.join.inspect])
    end

    return good.join
  end

  def reset
    self.command_start = true
    self.lex_strterm   = nil
    self.token         = nil
    self.yacc_value    = nil

    @src       = nil
    @lex_state = nil
  end

  def src= src
    raise "bad src: #{src.inspect}" unless String === src
    @src = RPStringScanner.new(src)
  end

  def tokadd_escape term # 20 lines
    case
    when src.scan(/\\\n/) then
      # just ignore
    when src.scan(/\\([0-7]{1,3}|x[0-9a-fA-F]{1,2})/) then
      self.string_buffer << src.matched
    when src.scan(/\\([MC]-|c)(?=\\)/) then
      self.string_buffer << src.matched
      self.tokadd_escape term
    when src.scan(/\\([MC]-|c)(.)/) then
      self.string_buffer << src.matched
    when src.scan(/\\[McCx]/) then
      rb_compile_error "Invalid escape character syntax"
    when src.scan(/\\(.)/m) then
      self.string_buffer << src.matched
    else
      rb_compile_error "Invalid escape character syntax"
    end
  end

  def tokadd_string(func, term, paren) # 105 lines
    awords = (func & STR_FUNC_AWORDS) != 0
    escape = (func & STR_FUNC_ESCAPE) != 0
    expand = (func & STR_FUNC_EXPAND) != 0
    regexp = (func & STR_FUNC_REGEXP) != 0
    symbol = (func & STR_FUNC_SYMBOL) != 0

    paren_re = paren.nil? ? nil : Regexp.new(Regexp.escape(paren))
    term_re  = Regexp.new(Regexp.escape(term))

    until src.eos? do
      c = nil
      handled = true
      case
      when self.nest == 0 && src.scan(term_re) then
        src.pos -= 1
        break
      when paren_re && src.scan(paren_re) then
        self.nest += 1
      when src.scan(term_re) then
        self.nest -= 1
      when awords && src.scan(/\s/) then
        src.pos -= 1
        break
      when expand && src.scan(/#(?=[\$\@\{])/) then
        src.pos -= 1
        break
      when expand && src.scan(/#(?!\n)/) then
        # do nothing
      when src.check(/\\/) then
        case
        when awords && src.scan(/\\\n/) then
          string_buffer << "\n"
          next
        when awords && src.scan(/\\\s/) then
          c = ' '
        when expand && src.scan(/\\\n/) then
          next
        when regexp && src.check(/\\/) then
          self.tokadd_escape term
          next
        when expand && src.scan(/\\/) then
          c = self.read_escape
        when src.scan(/\\\n/) then
          # do nothing
        when src.scan(/\\\\/) then
          string_buffer << '\\' if escape
          c = '\\'
        when src.scan(/\\/) then
          unless src.scan(term_re) || paren.nil? || src.scan(paren_re) then
            string_buffer << "\\"
          end
        else
          handled = false
        end
      else
        handled = false
      end # case

      unless handled then

        t = Regexp.escape term
        x = Regexp.escape(paren) if paren && paren != "\000"
        re = if awords then
               /[^#{t}#{x}\#\0\\\n\ ]+|./ # |. to pick up whatever
             else
               /[^#{t}#{x}\#\0\\]+|./
             end

        src.scan re
        c = src.matched

        rb_compile_error "symbol cannot contain '\\0'" if symbol && c =~ /\0/
      end # unless handled

      c ||= src.matched
      string_buffer << c
    end # until

    c ||= src.matched
    c = RubyLexer::EOF if src.eos?


    return c
  end

  def unescape s

    r = {
      "a"    => "\007",
      "b"    => "\010",
      "e"    => "\033",
      "f"    => "\f",
      "n"    => "\n",
      "r"    => "\r",
      "s"    => " ",
      "t"    => "\t",
      "v"    => "\13",
      "\\"   => '\\',
      "\n"   => "",
      "C-\?" => 127.chr,
      "c\?"  => 127.chr,
    }[s]

    return r if r

    case s
    when /^[0-7]{1,3}/ then
      $&.to_i(8).chr
    when /^x([0-9a-fA-F]{1,2})/ then
      $1.to_i(16).chr
    when /^M-(.)/ then
      ($1[0].ord | 0x80).chr
    when /^(C-|c)(.)/ then
      ($2[0].ord & 0x9f).chr
    when /^[McCx0-9]/ then
      rb_compile_error("Invalid escape character syntax")
    else
      s
    end
  end

  def warning s
    # do nothing for now
  end

  ##
  # Returns the next token. Also sets yy_val is needed.
  #
  # @return Description of the Returned Value

  def yylex # 826 lines

    c = ''
    space_seen = false
    command_state = false
    src = self.src

    self.token = nil
    self.yacc_value = nil

    return yylex_string if lex_strterm

    command_state = self.command_start
    self.command_start = false

    last_state = lex_state

    loop do # START OF CASE
      if src.scan(/[\ \t\r\f\v]/) then # \s - \n + \v
        space_seen = true
        next
      elsif src.check(/[^a-zA-Z]/) then
        if src.scan(/\n|#/) then
          self.lineno = nil
          c = src.matched
          if c == '#' then
            src.pos -= 1

            while src.scan(/\s*#.*(\n+|\z)/) do
              @comments << src.matched.gsub(/^ +#/, '#').gsub(/^ +$/, '')
            end

            if src.eos? then
              return RubyLexer::EOF
            end
          end

          # Replace a string of newlines with a single one
          src.scan(/\n+/)

          if [:expr_beg, :expr_fname,
              :expr_dot, :expr_class].include? lex_state then
            next
          end

          self.command_start = true
          self.lex_state = :expr_beg
          return :tNL
        elsif src.scan(/[\]\)\}]/) then
          cond.lexpop
          cmdarg.lexpop
          self.lex_state = :expr_end
          self.yacc_value = src.matched
          result = {
            ")" => :tRPAREN,
            "]" => :tRBRACK,
            "}" => :tRCURLY
          }[src.matched]
          return result
        elsif src.scan(/\.\.\.?|,|![=~]?/) then
          self.lex_state = :expr_beg
          tok = self.yacc_value = src.matched
          return TOKENS[tok]
        elsif src.check(/\./) then
          if src.scan(/\.\d/) then
            rb_compile_error "no .<digit> floating literal anymore put 0 before dot"
          elsif src.scan(/\./) then
            self.lex_state = :expr_dot
            self.yacc_value = "."
            return :tDOT
          end
        elsif src.scan(/\(/) then
          result = :tLPAREN2
          self.command_start = true

          if lex_state == :expr_beg || lex_state == :expr_mid then
            result = :tLPAREN
          elsif space_seen then
            if lex_state == :expr_cmdarg then
              result = :tLPAREN_ARG
            elsif lex_state == :expr_arg then
              warning("don't put space before argument parentheses")
              result = :tLPAREN2
            end
          end

          self.expr_beg_push "("

          return result
        elsif src.check(/\=/) then
          if src.scan(/\=\=\=|\=\=|\=~|\=>|\=(?!begin\b)/) then
            self.fix_arg_lex_state
            tok = self.yacc_value = src.matched
            return TOKENS[tok]
          elsif src.scan(/\=begin(?=\s)/) then
            # @comments << '=' << src.matched
            @comments << src.matched

            unless src.scan(/.*?\n=end( |\t|\f)*[^(\n|\z)]*(\n|\z)/m) then
              @comments.clear
              rb_compile_error("embedded document meets end of file")
            end

            @comments << src.matched

            next
          else
            raise "you shouldn't be able to get here"
          end
        elsif src.scan(/\"(#{ESC_RE}|#(#{ESC_RE}|[^\{\#\@\$\"\\])|[^\"\\\#])*\"/o) then
          self.yacc_value = src.matched[1..-2].gsub(ESC_RE) { unescape $1 }
          self.lex_state = :expr_end
          return :tSTRING
        elsif src.scan(/\"/) then # FALLBACK
          self.lex_strterm = [:strterm, STR_DQUOTE, '"', "\0"] # TODO: question this
          self.yacc_value = "\""
          return :tSTRING_BEG
        elsif src.scan(/\@\@?\w*/) then
          self.token = src.matched

          rb_compile_error "`#{token}` is not allowed as a variable name" if
            token =~ /\@\d/

          return process_token(command_state)
        elsif src.scan(/\:\:/) then
          if (lex_state == :expr_beg ||
              lex_state == :expr_mid ||
              lex_state == :expr_class ||
              (lex_state.is_argument && space_seen)) then
            self.lex_state = :expr_beg
            self.yacc_value = "::"
            return :tCOLON3
          end

          self.lex_state = :expr_dot
          self.yacc_value = "::"
          return :tCOLON2
        elsif lex_state != :expr_end && lex_state != :expr_endarg && src.scan(/:([a-zA-Z_]\w*(?:[?!]|=(?!>))?)/) then
          self.yacc_value = src[1]
          self.lex_state = :expr_end
          return :tSYMBOL
        elsif src.scan(/\:/) then
          # ?: / then / when
          if (lex_state == :expr_end || lex_state == :expr_endarg||
              src.check(/\s/)) then
            self.lex_state = :expr_beg
            self.yacc_value = ":"
            return :tCOLON
          end

          case
          when src.scan(/\'/) then
            self.lex_strterm = [:strterm, STR_SSYM, src.matched, "\0"]
          when src.scan(/\"/) then
            self.lex_strterm = [:strterm, STR_DSYM, src.matched, "\0"]
          end

          self.lex_state = :expr_fname
          self.yacc_value = ":"
          return :tSYMBEG
        elsif src.check(/[0-9]/) then
          return parse_number
        elsif src.scan(/\[/) then
          result = src.matched

          if lex_state == :expr_fname || lex_state == :expr_dot then
            self.lex_state = :expr_arg
            case
            when src.scan(/\]\=/) then
              self.yacc_value = "[]="
              return :tASET
            when src.scan(/\]/) then
              self.yacc_value = "[]"
              return :tAREF
            else
              rb_compile_error "unexpected '['"
            end
          elsif lex_state == :expr_beg || lex_state == :expr_mid then
            result = :tLBRACK
          elsif lex_state.is_argument && space_seen then
            result = :tLBRACK
          end

          self.expr_beg_push "["

          return result
        elsif src.scan(/\'(\\.|[^\'])*\'/) then
          self.yacc_value = src.matched[1..-2].gsub(/\\\\/, "\\").gsub(/\\'/, "'")
          self.lex_state = :expr_end
          return :tSTRING
        elsif src.check(/\|/) then
          if src.scan(/\|\|\=/) then
            self.lex_state = :expr_beg
            self.yacc_value = "||"
            return :tOP_ASGN
          elsif src.scan(/\|\|/) then
            self.lex_state = :expr_beg
            self.yacc_value = "||"
            return :tOROP
          elsif src.scan(/\|\=/) then
            self.lex_state = :expr_beg
            self.yacc_value = "|"
            return :tOP_ASGN
          elsif src.scan(/\|/) then
            self.fix_arg_lex_state
            self.yacc_value = "|"
            return :tPIPE
          end
        elsif src.scan(/\{/) then
          result = if lex_state.is_argument || lex_state == :expr_end then
                     :tLCURLY      #  block (primary)
                   elsif lex_state == :expr_endarg then
                     :tLBRACE_ARG  #  block (expr)
                   else
                     :tLBRACE      #  hash
                   end

          self.expr_beg_push "{"
          self.command_start = true unless result == :tLBRACE

          return result
        elsif src.scan(/[+-]/) then
          sign = src.matched
          utype, type = if sign == "+" then
                          [:tUPLUS, :tPLUS]
                        else
                          [:tUMINUS, :tMINUS]
                        end

          if lex_state == :expr_fname || lex_state == :expr_dot then
            self.lex_state = :expr_arg
            if src.scan(/@/) then
              self.yacc_value = "#{sign}@"
              return utype
            else
              self.yacc_value = sign
              return type
            end
          end

          if src.scan(/\=/) then
            self.lex_state = :expr_beg
            self.yacc_value = sign
            return :tOP_ASGN
          end

          if (lex_state == :expr_beg || lex_state == :expr_mid ||
              (lex_state.is_argument && space_seen && !src.check(/\s/))) then
            if lex_state.is_argument then
              arg_ambiguous
            end

            self.lex_state = :expr_beg
            self.yacc_value = sign

            if src.check(/\d/) then
              if utype == :tUPLUS then
                return self.parse_number
              else
                return :tUMINUS_NUM
              end
            end

            return utype
          end

          self.lex_state = :expr_beg
          self.yacc_value = sign
          return type
        elsif src.check(/\*/) then
          if src.scan(/\*\*=/) then
            self.lex_state = :expr_beg
            self.yacc_value = "**"
            return :tOP_ASGN
          elsif src.scan(/\*\*/) then
            self.yacc_value = "**"
            self.fix_arg_lex_state
            return :tPOW
          elsif src.scan(/\*\=/) then
            self.lex_state = :expr_beg
            self.yacc_value = "*"
            return :tOP_ASGN
          elsif src.scan(/\*/) then
            result = if lex_state.is_argument && space_seen && src.check(/\S/) then
                       warning("`*' interpreted as argument prefix")
                       :tSTAR
                     elsif lex_state == :expr_beg || lex_state == :expr_mid then
                       :tSTAR
                     else
                       :tSTAR2
                     end
            self.yacc_value = "*"
            self.fix_arg_lex_state

            return result
          end
        elsif src.check(/\</) then
          if src.scan(/\<\=\>/) then
            self.fix_arg_lex_state
            self.yacc_value = "<=>"
            return :tCMP
          elsif src.scan(/\<\=/) then
            self.fix_arg_lex_state
            self.yacc_value = "<="
            return :tLEQ
          elsif src.scan(/\<\<\=/) then
            self.fix_arg_lex_state
            self.lex_state = :expr_beg
            self.yacc_value = "\<\<"
            return :tOP_ASGN
          elsif src.scan(/\<\</) then
            if (! [:expr_end,    :expr_dot,
                   :expr_endarg, :expr_class].include?(lex_state) &&
                (!lex_state.is_argument || space_seen)) then
              tok = self.heredoc_identifier
              if tok then
                return tok
              end
            end

            self.fix_arg_lex_state
            self.yacc_value = "\<\<"
            return :tLSHFT
          elsif src.scan(/\</) then
            self.fix_arg_lex_state
            self.yacc_value = "<"
            return :tLT
          end
        elsif src.check(/\>/) then
          if src.scan(/\>\=/) then
            self.fix_arg_lex_state
            self.yacc_value = ">="
            return :tGEQ
          elsif src.scan(/\>\>=/) then
            self.fix_arg_lex_state
            self.lex_state = :expr_beg
            self.yacc_value = ">>"
            return :tOP_ASGN
          elsif src.scan(/\>\>/) then
            self.fix_arg_lex_state
            self.yacc_value = ">>"
            return :tRSHFT
          elsif src.scan(/\>/) then
            self.fix_arg_lex_state
            self.yacc_value = ">"
            return :tGT
          end
        elsif src.scan(/\`/) then
          self.yacc_value = "`"
          case lex_state
          when :expr_fname then
            self.lex_state = :expr_end
            return :tBACK_REF2
          when :expr_dot then
            self.lex_state = if command_state then
                               :expr_cmdarg
                             else
                               :expr_arg
                             end
            return :tBACK_REF2
          end
          self.lex_strterm = [:strterm, STR_XQUOTE, '`', "\0"]
          return :tXSTRING_BEG
        elsif src.scan(/\?/) then
          if lex_state == :expr_end || lex_state == :expr_endarg then
            self.lex_state = :expr_beg
            self.yacc_value = "?"
            return :tEH
          end

          if src.eos? then
            rb_compile_error "incomplete character syntax"
          end

          if src.check(/\s|\v/) then
            unless lex_state.is_argument then
              c2 = { " " => 's',
                    "\n" => 'n',
                    "\t" => 't',
                    "\v" => 'v',
                    "\r" => 'r',
                    "\f" => 'f' }[src.matched]

              if c2 then
                warning("invalid character syntax; use ?\\" + c2)
              end
            end

            # ternary
            self.lex_state = :expr_beg
            self.yacc_value = "?"
            return :tEH
          elsif src.check(/\w(?=\w)/) then # ternary, also
            self.lex_state = :expr_beg
            self.yacc_value = "?"
            return :tEH
          end

          c = if src.scan(/\\/) then
                self.read_escape
              else
                src.getch
              end
          self.lex_state = :expr_end
          self.yacc_value = c[0].ord & 0xff
          return :tINTEGER
        elsif src.check(/\&/) then
          if src.scan(/\&\&\=/) then
            self.yacc_value = "&&"
            self.lex_state = :expr_beg
            return :tOP_ASGN
          elsif src.scan(/\&\&/) then
            self.lex_state = :expr_beg
            self.yacc_value = "&&"
            return :tANDOP
          elsif src.scan(/\&\=/) then
            self.yacc_value = "&"
            self.lex_state = :expr_beg
            return :tOP_ASGN
          elsif src.scan(/&/) then
            result = if lex_state.is_argument && space_seen &&
                         !src.check(/\s/) then
                       warning("`&' interpreted as argument prefix")
                       :tAMPER
                     elsif lex_state == :expr_beg || lex_state == :expr_mid then
                       :tAMPER
                     else
                       :tAMPER2
                     end

            self.fix_arg_lex_state
            self.yacc_value = "&"
            return result
          end
        elsif src.scan(/\//) then
          if lex_state == :expr_beg || lex_state == :expr_mid then
            self.lex_strterm = [:strterm, STR_REGEXP, '/', "\0"]
            self.yacc_value = "/"
            return :tREGEXP_BEG
          end

          if src.scan(/\=/) then
            self.yacc_value = "/"
            self.lex_state = :expr_beg
            return :tOP_ASGN
          end

          if lex_state.is_argument && space_seen then
            unless src.scan(/\s/) then
              arg_ambiguous
              self.lex_strterm = [:strterm, STR_REGEXP, '/', "\0"]
              self.yacc_value = "/"
              return :tREGEXP_BEG
            end
          end

          self.fix_arg_lex_state
          self.yacc_value = "/"

          return :tDIVIDE
        elsif src.scan(/\^=/) then
          self.lex_state = :expr_beg
          self.yacc_value = "^"
          return :tOP_ASGN
        elsif src.scan(/\^/) then
          self.fix_arg_lex_state
          self.yacc_value = "^"
          return :tCARET
        elsif src.scan(/\;/) then
          self.command_start = true
          self.lex_state = :expr_beg
          self.yacc_value = ";"
          return :tSEMI
        elsif src.scan(/\~/) then
          if lex_state == :expr_fname || lex_state == :expr_dot then
            src.scan(/@/)
          end

          self.fix_arg_lex_state
          self.yacc_value = "~"

          return :tTILDE
        elsif src.scan(/\\/) then
          if src.scan(/\n/) then
            self.lineno = nil
            space_seen = true
            next
          end
          rb_compile_error "bare backslash only allowed before newline"
        elsif src.scan(/\%/) then
          if lex_state == :expr_beg || lex_state == :expr_mid then
            return parse_quote
          end

          if src.scan(/\=/) then
            self.lex_state = :expr_beg
            self.yacc_value = "%"
            return :tOP_ASGN
          end

          if lex_state.is_argument && space_seen && ! src.check(/\s/) then
            return parse_quote
          end

          self.fix_arg_lex_state
          self.yacc_value = "%"

          return :tPERCENT
        elsif src.check(/\$/) then
          if src.scan(/(\$_)(\w+)/) then
            self.lex_state = :expr_end
            self.token = src.matched
            return process_token(command_state)
          elsif src.scan(/\$_/) then
            self.lex_state = :expr_end
            self.token = src.matched
            self.yacc_value = src.matched
            return :tGVAR
          elsif src.scan(/\$[~*$?!@\/\\;,.=:<>\"]|\$-\w?/) then
            self.lex_state = :expr_end
            self.yacc_value = src.matched
            return :tGVAR
          elsif src.scan(/\$([\&\`\'\+])/) then
            self.lex_state = :expr_end
            # Explicit reference to these vars as symbols...
            if last_state == :expr_fname then
              self.yacc_value = src.matched
              return :tGVAR
            else
              self.yacc_value = src[1].to_sym
              return :tBACK_REF
            end
          elsif src.scan(/\$([1-9]\d*)/) then
            self.lex_state = :expr_end
            if last_state == :expr_fname then
              self.yacc_value = src.matched
              return :tGVAR
            else
              self.yacc_value = src[1].to_i
              return :tNTH_REF
            end
          elsif src.scan(/\$0/) then
            self.lex_state = :expr_end
            self.token = src.matched
            return process_token(command_state)
          elsif src.scan(/\$\W|\$\z/) then # TODO: remove?
            self.lex_state = :expr_end
            self.yacc_value = "$"
            return "$"
          elsif src.scan(/\$\w+/)
            self.lex_state = :expr_end
            self.token = src.matched
            return process_token(command_state)
          end
        elsif src.check(/\_/) then
          if src.beginning_of_line? && src.scan(/\__END__(\n|\Z)/) then
            self.lineno = nil
            return RubyLexer::EOF
          elsif src.scan(/\_\w*/) then
            self.token = src.matched
            return process_token(command_state)
          end
        end
      end # END OF CASE

      if src.scan(/\004|\032|\000/) || src.eos? then # ^D, ^Z, EOF
        return RubyLexer::EOF
      else # alpha check
        if src.scan(/\W/) then
          rb_compile_error "Invalid char #{src.matched.inspect} in expression"
        end
      end

      self.token = src.matched if self.src.scan(/\w+/)

      return process_token(command_state)
    end
  end

  def process_token(command_state)

    token << src.matched if token =~ /^\w/ && src.scan(/[\!\?](?!=)/)

    result = nil
    last_state = lex_state


    case token
    when /^\$/ then
      self.lex_state, result = :expr_end, :tGVAR
    when /^@@/ then
      self.lex_state, result = :expr_end, :tCVAR
    when /^@/ then
      self.lex_state, result = :expr_end, :tIVAR
    else
      if token =~ /[!?]$/ then
        result = :tFID
      else
        if lex_state == :expr_fname then
          # ident=, not =~ => == or followed by =>
          # TODO test lexing of a=>b vs a==>b
          if src.scan(/=(?:(?![~>=])|(?==>))/) then
            result = :tIDENTIFIER
            token << src.matched
          end
        end

        if src.scan(/:(?!:)/)
            result = :tHASHKEY
            token << src.matched
            self.yacc_value = token
            return result
        end

        result ||= if token =~ /^[A-Z]/ then
                     :tCONSTANT
                   else
                     :tIDENTIFIER
                   end
      end

      unless lex_state == :expr_dot then
        # See if it is a reserved word.
        keyword = RubyParser::Keyword.keyword token

        if keyword then
          state           = lex_state
          self.lex_state  = keyword.state
          self.yacc_value = [token, src.lineno]

          if state == :expr_fname then
            self.yacc_value = keyword.name
            return keyword.id0
          end

          if keyword.id0 == :kDO then
            self.command_start = true
            return :kDO_COND  if cond.is_in_state
            return :kDO_BLOCK if cmdarg.is_in_state && state != :expr_cmdarg
            return :kDO_BLOCK if state == :expr_endarg
            return :kDO
          end

          return keyword.id0 if state == :expr_beg or state == :expr_value

          self.lex_state = :expr_beg if keyword.id0 != keyword.id1

          return keyword.id1
        end
      end

      if (lex_state == :expr_beg || lex_state == :expr_mid ||
          lex_state == :expr_dot || lex_state == :expr_arg ||
          lex_state == :expr_cmdarg) then
        if command_state then
          self.lex_state = :expr_cmdarg
        else
          self.lex_state = :expr_arg
        end
      else
        self.lex_state = :expr_end
      end
    end

    self.yacc_value = token


    self.lex_state = :expr_end if
      last_state != :expr_dot && self.parser.env[token.to_sym] == :lvar

    return result
  end

  def yylex_string # 23 lines
    token = if lex_strterm[0] == :heredoc then
              self.heredoc lex_strterm
            else
              self.parse_string lex_strterm
            end

    if token == :tSTRING_END || token == :tREGEXP_END then
      self.lineno      = nil
      self.lex_strterm = nil
      self.lex_state   = :expr_end
    end

    return token
  end
end
