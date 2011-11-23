require 'set'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/render_helper'

#Processes aliasing in templates.
#Handles calls to +render+.
class Brakeman::TemplateAliasProcessor < Brakeman::AliasProcessor
  include Brakeman::RenderHelper

  FORM_METHODS = Set.new([:form_for, :remote_form_for, :form_remote_for])

  def initialize tracker, template
    super()
    @tracker = tracker
    @template = template
  end

  #Process template
  def process_template name, args
    super name, args, "Template:#{@template[:name]}"
  end

  #Determine template name
  def template_name name
    unless name.to_s.include? "/"
      name = "#{@template[:name].to_s.match(/^(.*\/).*$/)[1]}#{name}"
    end
    name
  end

  #Looks for form methods and iterating over collections of Models
  def process_call_with_block exp
    process_default exp
    
    call = exp[1]
    target = call[1]
    method = call[2]
    args = exp[2]
    block = exp[3]

    #Check for e.g. Model.find.each do ... end
    if method == :each and args and block and model = get_model_target(target)
      if sexp? args and args.node_type == :lasgn
        if model == target[1]
          env[Sexp.new(:lvar, args[1])] = Sexp.new(:call, model, :new, Sexp.new(:arglist))
        else
          env[Sexp.new(:lvar, args[1])] = Sexp.new(:call, Sexp.new(:const, Brakeman::Tracker::UNKNOWN_MODEL), :new, Sexp.new(:arglist))
        end
        
        process block if sexp? block
      end
    elsif FORM_METHODS.include? method
      if sexp? args and args.node_type == :lasgn
        env[Sexp.new(:lvar, args[1])] = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new, Sexp.new(:arglist)) 

        process block if sexp? block
      end
    end

    exp
  end

  alias process_iter process_call_with_block

  #Checks if +exp+ is a call to Model.all or Model.find*
  def get_model_target exp
    if call? exp
      target = exp[1]

      if exp[2] == :all or exp[2].to_s[0,4] == "find"
        models = Set.new @tracker.models.keys

        begin
          name = class_name target
          return target if models.include?(name)
        rescue StandardError
        end

      end

      return get_model_target(target)
    end

    false
  end
end
