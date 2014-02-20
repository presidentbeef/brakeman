require 'brakeman/processors/base_processor'

#Base Processor for templates/views
class Brakeman::TemplateProcessor < Brakeman::BaseProcessor

  #Initializes template information.
  def initialize tracker, template_name, called_from = nil, file_name = nil
    super(tracker) 
    @current_template = { :name => template_name,
                          :caller => called_from,
                          :partial => template_name.to_s[0,1] == "_",
                          :outputs => [],
                          :src => nil, #set in Processor
                          :type => nil, #set in Processor
                          :file => file_name } 
    if called_from
      template_name = (template_name.to_s + "." + called_from.to_s).to_sym
    end

    tracker.templates[template_name] = @current_template

    @inside_concat = false
  end

  #Process the template Sexp.
  def process exp
    begin
      super
    rescue => e
      except = e.exception("Error when processing #{@current_template[:name]}: #{e.message}")
      except.set_backtrace(e.backtrace)
      raise except
    end
  end

  #Ignore initial variable assignment
  def process_lasgn exp
    if exp.lhs == :_erbout and exp.rhs.node_type == :str  #ignore
      ignore
    elsif exp.lhs == :_buf and exp.rhs.node_type == :str
      ignore
    else
      exp.rhs = process exp.rhs
      exp
    end
  end

  #Adds output to the list of outputs.
  def process_output exp
    exp.value = process exp.value
    @current_template[:outputs] << exp unless exp.original_line
    exp
  end

  def process_escaped_output exp
    process_output exp
  end
end
