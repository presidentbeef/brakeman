require 'brakeman/processors/template_processor'

#Processes ERB templates
#(those ending in .html.erb or .rthml).
class Brakeman::ErbTemplateProcessor < Brakeman::TemplateProcessor
  
  #s(:call, TARGET, :method, s(:arglist))
  def process_call exp
    target = exp[1]
    if sexp? target
      target = process target
    end
    method = exp[2]
    
    #_erbout is the default output variable for erb
    if target and target[1] == :_erbout
      if method == :concat
        @inside_concat = true
        args = exp[3] = process(exp[3])
        @inside_concat = false

        if args.length > 2
          raise Exception.new("Did not expect more than a single argument to _erbout.concat")
        end

        args = args[1]

        if args.node_type == :call and args[2] == :to_s #erb always calls to_s on output
          args = args[1]
        end

        if args.node_type == :str #ignore plain strings
          ignore
        else
          s = Sexp.new :output, args
          s.line(exp.line)
          @current_template[:outputs] << s
          s
        end
      elsif method == :force_encoding
        ignore
      else
        abort "Unrecognized action on _erbout: #{method}"
      end
    elsif target == nil and method == :render
      exp[3] = process(exp[3])
      make_render exp
    else
      args = exp[3] = process(exp[3])
      call = Sexp.new :call, target, method, args
      call.line(exp.line)
      call
    end
  end

  #Process block, removing irrelevant expressions
  def process_block exp
    exp.shift
    if @inside_concat
      @inside_concat = false
      exp[0..-2].each do |e|
        process e
      end
      @inside_concat = true
      process exp[-1]
    else
      exp.map! do |e|
        res = process e
        if res.empty? or res == ignore
          nil
        elsif sexp? res and res.node_type == :lvar and res[1] == :_erbout
          nil

        else
          res
        end
      end
      block = Sexp.new(:rlist).concat(exp).compact
      block.line(exp.line)
      block
    end
  end

end
