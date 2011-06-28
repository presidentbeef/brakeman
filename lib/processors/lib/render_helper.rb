require 'digest/sha1'

#Processes a call to render() in a controller or template
module RenderHelper

  #Process s(:render, TYPE, OPTIONS)
  def process_render exp
    process_default exp
    @rendered = true
    case exp[1]
    when :action
      process_action exp[2][1], exp[3]
    when :default
      begin
        template = exp[3][2][1]
      rescue Exception => e
          puts "Bug to fix, giving #{e.message}"
          return exp
      end
      process_template template, exp[3]
    when :partial
      process_partial exp[2], exp[3]
    when :nothing
    end
    exp
  end

  #Processes layout
  def process_layout name = nil
    layout = name || layout_name
    return unless layout

    process_template layout, nil
  end

  #Determines file name for partial and then processes it
  def process_partial name, args
    if name == "" or !(string? name or symbol? name)
      return
    end

    names = name[1].to_s.split("/")
    names[-1] = "_" + names[-1]
    process_template template_name(names.join("/")), args
  end

  #Processes a given action
  def process_action name, args
    process_template template_name(name), args
  end

  #Processes a template, adding any instance variables
  #to its environment.
  def process_template name, args, called_from = nil
    #Get scanned source for this template
    name = name.to_s.gsub(/^\//, "")
    template = @tracker.templates[name.to_sym]
    unless template
      warn "[Notice] No such template: #{name}" if OPTIONS[:debug]
      return 
    end

    template_env = only_ivars

    #Hash the environment and the source of the template to avoid
    #pointlessly processing templates, which can become prohibitively
    #expensive in terms of time and memory.
    digest = Digest::SHA1.new.update(template_env.instance_variable_get(:@env).to_a.sort.to_s << template[:src].to_s).to_s.to_sym

    if @tracker.template_cache.include? digest
      #Already processed this template with identical environment
      return
    else
      @tracker.template_cache << digest

      options = get_options args

      #Process layout
      if string? options[:layout]
        process_template "layouts/#{options[:layout][1]}", nil
      elsif sexp? options[:layout] and options[:layout][0] == :false
        #nothing
      elsif not template[:name].to_s.match(/[^\/_][^\/]+$/)
        #Don't do this for partials
        
        process_layout
      end

      if hash? options[:locals]
        hash_iterate options[:locals] do |key, value|
          template_env[Sexp.new(:call, nil, key[1], Sexp.new(:arglist))] = value
        end
      end

      if options[:collection]

        #The collection name is the name of the partial without the leading
        #underscore.
        variable = template[:name].to_s.match(/[^\/_][^\/]+$/)[0].to_sym

        #Unless the :as => :variable_name option is used
        if options[:as]
          if string? options[:as] or symbol? options[:as]
            variable = options[:as][1].to_sym
          end
        end

        template_env[Sexp.new(:call, nil, variable, Sexp.new(:arglist))] = Sexp.new(:call, Sexp.new(:const, Tracker::UNKNOWN_MODEL), :new, Sexp.new(:arglist))
      end

      #Run source through AliasProcessor with instance variables from the
      #current environment.
      #TODO: Add in :locals => { ... } to environment
      src = TemplateAliasProcessor.new(@tracker, template).process_safely(template[:src], template_env)

      #Run alias-processed src through the template processor to pull out
      #information and outputs.
      #This information will be stored in tracker.templates, but with a name
      #specifying this particular route. The original source should remain
      #pristine (so it can be processed within other environments).
      @tracker.processor.process_template name, src, template[:type], called_from
    end
  end

  #Override to process name, such as adding the controller name.
  def template_name name
    raise "RenderHelper#template_name should be overridden."
  end

  #Turn options Sexp into hash
  def get_options args
    options = {}
    return options unless hash? args

    hash_iterate args do |key, value|
      if symbol? key
        options[key[1]] = value
      end
    end

    options
  end
end
