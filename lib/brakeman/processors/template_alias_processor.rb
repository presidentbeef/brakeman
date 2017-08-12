require 'set'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/render_helper'
require 'brakeman/processors/lib/render_path'
require 'brakeman/tracker'

#Processes aliasing in templates.
#Handles calls to +render+.
class Brakeman::TemplateAliasProcessor < Brakeman::AliasProcessor
  include Brakeman::RenderHelper

  FORM_METHODS = Set[:form_for, :remote_form_for, :form_remote_for]

  def initialize tracker, template, called_from = nil
    super tracker
    @template = template
    @called_from = called_from
  end

  #Process template
  def process_template name, args, _, line = nil, file_name = nil
    @file_name = file_name || relative_path(@template.file || @tracker.templates[@template.name])

    if @called_from
      if @called_from.include_template? name
        Brakeman.debug "Skipping circular render from #{@template.name} to #{name}"
        return
      end

      super name, args, @called_from.dup.add_template_render(@template.name, line, @file_name)
    else
      super name, args, Brakeman::RenderPath.new.add_template_render(@template.name, line, @file_name)
    end
  end

  #Determine template name
  def template_name name
    if !name.to_s.include?('/') && @template.name.to_s.include?('/')
      name = "#{@template.name.to_s.match(/^(.*\/).*$/)[1]}#{name}"
    end
    name
  end

  UNKNOWN_MODEL_CALL = Sexp.new(:call, Sexp.new(:const, Brakeman::Tracker::UNKNOWN_MODEL), :new)
  FORM_BUILDER_CALL = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new)

  #Looks for form methods and iterating over collections of Models
  def process_iter exp
    process_default exp

    call = exp.block_call

    if call? call
      target = call.target
      method = call.method
      arg = exp.block_args.first_param
      block = exp.block

      #Check for e.g. Model.find.each do ... end
      if method == :each and arg and block and model = get_model_target(target)
        if arg.is_a? Symbol
          if model == target.target
            env[Sexp.new(:lvar, arg)] = Sexp.new(:call, model, :new)
          else
            env[Sexp.new(:lvar, arg)] = UNKNOWN_MODEL_CALL
          end

          process block if sexp? block
        end
      elsif FORM_METHODS.include? method
        if arg.is_a? Symbol
          env[Sexp.new(:lvar, arg)] = FORM_BUILDER_CALL

          process block if sexp? block
        end
      end
    end

    exp
  end

  COLLECTION_METHODS = [:all, :find, :select, :where]

  #Checks if +exp+ is a call to Model.all or Model.find*
  def get_model_target exp
    if call? exp
      target = exp.target

      if COLLECTION_METHODS.include? exp.method or exp.method.to_s[0,4] == "find"
        models = Set.new @tracker.models.keys
        name = class_name target
        return target if models.include?(name)
      end

      return get_model_target(target)
    end

    false
  end

  #Ignore `<<` calls on template variables which are used by the templating
  #library (HAML, ERB, etc.)
  def find_push_target exp
    if sexp? exp
      if exp.node_type == :lvar and (exp.value == :_buf or exp.value == :_erbout)
        return nil
      elsif exp.node_type == :ivar and exp.value == :@output_buffer
        return nil
      elsif exp.node_type == :call and call? exp.target and
        exp.target.method == :_hamlout and exp.method == :buffer

        return nil
      end
    end

    super
  end
end
