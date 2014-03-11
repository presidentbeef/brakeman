require 'ruby2ruby'
require 'brakeman/util'

#Produces formatted output strings from Sexps.
#Recommended usage is
#
#  OutputProcessor.new.format(Sexp.new(:str, "hello"))
class Brakeman::OutputProcessor < Ruby2Ruby
  include Brakeman::Util

  #Copies +exp+ and then formats it.
  def format exp
    process(exp.deep_clone) || "[Format Error]"
  end

  alias process_safely format

  def process exp
    begin
      super exp if sexp? exp and not exp.empty?
    rescue => e
      Brakeman.debug "While formatting #{exp}: #{e}\n#{e.backtrace.join("\n")}"
    end
  end

  def process_lvar exp
    out = "(local #{exp[0]})"
    exp.clear
    out
  end

  def process_ignore exp
    exp.clear
    "[ignored]"
  end

  def process_params exp
    exp.clear
    "params"
  end

  def process_session exp
    exp.clear
    "session"
  end

  def process_cookies exp
    exp.clear
    "cookies"
  end

  def process_string_interp exp
    out = '"'
    exp.each do |e|
      if e.is_a? String
        out << e
      else
        res = process e
        out << res unless res == "" 
      end
    end
    out << '"'
    exp.clear
    out
  end

  def process_string_eval exp
    out = "\#{#{process(exp[0])}}"
    exp.clear
    out
  end

  def process_dxstr exp
    out = "`"
    out << exp.map! do |e|
      if e.is_a? String
        e
      elsif string? e
        e[1]
      else
        process e
      end
    end.join
    exp.clear
    out << "`"
  end

  def process_rlist exp
    out = exp.map do |e|
      res = process e
      if res == ""
        nil
      else
        res
      end
    end.compact.join("\n")
    exp.clear
    out
  end

  def process_defn exp
    # Copied from Ruby2Ruby except without the whole
    # "convert methods to attr_*" stuff
    name = exp.shift
    args = process exp.shift
    args = "" if args == "()"

    exp.shift if exp == s(s(:nil)) # empty it out of a default nil expression

    body = []
    until exp.empty? do
      body << indent(process(exp.shift))
    end

    body << indent("# do nothing") if body.empty?

    body = body.join("\n")

    return "def #{name}#{args}\n#{body}\nend".gsub(/\n\s*\n+/, "\n")
  end

  alias process_methdef process_defn

  def process_call_with_block exp
    call = process exp[0]
    block = process_rlist exp[2..-1]
    out = "#{call} do\n #{block}\n end"
    exp.clear
    out
  end

  def process_output exp
    out = if exp[0].node_type == :str
            ""
          else
            res = process exp[0]

            if res == ""
              ""
            else
              "[Output] #{res}"
            end
          end
    exp.clear
    out
  end

  def process_escaped_output exp
    out = if exp[0].node_type == :str
            ""
          else
            res = process exp[0]

            if res == ""
              ""
            else
              "[Escaped Output] #{res}"
            end
          end
    exp.clear
    out
  end


  def process_format exp
    out = if exp[0].node_type == :str or exp[0].node_type == :ignore
            ""
          else
            res = process exp[0]

            if res == ""
              ""
            else
              "[Format] #{res}"
            end
          end
    exp.clear
    out
  end

  def process_format_escaped exp
    out = if exp[0].node_type == :str or exp[0].node_type == :ignore
            ""
          else
            res = process exp[0]

            if res == ""
              ""
            else
              "[Escaped] #{res}"
            end
          end
    exp.clear
    out
  end

  def process_const exp
    if exp[0] == Brakeman::Tracker::UNKNOWN_MODEL
      exp.clear
      "(Unresolved Model)"
    else
      out = exp[0].to_s
      exp.clear
      out
    end
  end

  def process_render exp
    exp[1] = process exp[1] if sexp? exp[1]
    exp[2] = process exp[2] if sexp? exp[2]
    out = "render(#{exp[0]} => #{exp[1]}, #{exp[2]})"
    exp.clear
    out
  end

  #This is copied from Ruby2Ruby, except the :string_eval type has been added
  def util_dthing(type, exp)
    s = []

    # first item in sexp is a string literal
    s << dthing_escape(type, exp.shift)

    until exp.empty?
      pt = exp.shift
      case pt
      when Sexp then
        case pt.first
        when :str then
          s << dthing_escape(type, pt.last)
        when :evstr, :string_eval then
          s << '#{' << process(pt) << '}' # do not use interpolation here
        else
          raise "unknown type: #{pt.inspect}"
        end
      else
        # HACK: raise "huh?: #{pt.inspect}" -- hitting # constants in regexps
        # do nothing for now
      end
    end

    s.join
  end

end
