Brakeman.load_brakeman_dependency 'ruby2ruby'
require 'brakeman/util'

#Produces formatted output strings from Sexps.
#Recommended usage is
#
#  OutputProcessor.new.format(Sexp.new(:str, "hello"))
class Brakeman::OutputProcessor < Ruby2Ruby
  include Brakeman::Util

  #Copies +exp+ and then formats it.
  def format exp, user_input = nil, &block
    @user_input = user_input
    @user_input_block = block
    process(exp.deep_clone) || "[Format Error]"
  end

  alias process_safely format

  def process exp
    begin
      if @user_input and @user_input == exp
        @user_input_block.call(exp, super(exp))
      else
        super exp if sexp? exp and not exp.empty?
      end
    rescue => e
      Brakeman.debug "While formatting #{exp}: #{e}\n#{e.backtrace.join("\n")}"
    end
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

  def process_iter exp
    call = process exp[0]
    block = process_rlist exp[2..-1]
    out = "#{call} do\n #{block}\n end"
    exp.clear
    out
  end

  def process_output exp
    output_format exp, "Output"
  end

  def process_escaped_output exp
    output_format exp, "Escaped Output"
  end


  def process_format exp
    output_format exp, "Format"
  end

  def process_format_escaped exp
    output_format exp, "Escaped"
  end

  def output_format exp, tag
    out = if exp[0].node_type == :str or exp[0].node_type == :ignore
            ""
          else
            res = process exp[0]

            if res == ""
              ""
            else
              "[#{tag}] #{res}"
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
end
