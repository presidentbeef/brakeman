require 'brakeman/processors/base_processor'

#Processes the Sexp from routes.rb. Stores results in tracker.routes.
#
#Note that it is only interested in determining what methods on which
#controllers are used as routes, not the generated URLs for routes.
class Brakeman::Rails2RoutesProcessor < Brakeman::BaseProcessor
  include Brakeman::RouteHelper

  attr_reader :map, :nested, :current_controller

  def initialize tracker
    super
    @map = Sexp.new(:lvar, :map)
    @nested = nil  #used for identifying nested targets
    @prefix = [] #Controller name prefix (a module name, usually)
    @current_controller = nil
    @with_options = nil #For use inside map.with_options
  end

  #Call this with parsed route file information.
  #
  #This method first calls RouteAliasProcessor#process_safely on the +exp+,
  #so it does not modify the +exp+.
  def process_routes exp
    process Brakeman::RouteAliasProcessor.new.process_safely(exp)
  end

  #Looking for mapping of routes
  def process_call exp
    target = exp[1]

    if target == map or target == nested
      process_map exp

    else
      process_default exp
    end

    exp
  end

  #Process a map.something call
  #based on the method used
  def process_map exp
    args = exp[3][1..-1]

    case exp[2]
    when :resource
      process_resource args
    when :resources
      process_resources args
    when :connect, :root
      process_connect args
    else
      process_named_route args
    end

    exp
  end

  #Look for map calls that take a block.
  #Otherwise, just do the default processing.
  def process_iter exp
    if exp[1][1] == map or exp[1][1] == nested
      method = exp[1][2]
      case method
      when :namespace
        process_namespace exp
      when :resources, :resource
        process_resources exp[1][3][1..-1]
        process_default exp[3] if exp[3]
      when :with_options
        process_with_options exp
      end
      exp
    else
      super
    end
  end

  #Process
  # map.resources :x, :controller => :y, :member => ...
  #etc.
  def process_resources exp
    controller = check_for_controller_name exp
    if controller
      self.current_controller = controller
      process_resource_options exp[-1]
    else
      exp.each do |argument|
        if sexp? argument and argument.node_type == :lit
          self.current_controller = exp[0][1]
          add_resources_routes
          process_resource_options exp[-1]
        end
      end
    end
  end

  #Process all the options that might be in the hash passed to
  #map.resource, et al.
  def process_resource_options exp
    if exp.nil? and @with_options
      exp = @with_options
    elsif @with_options
      exp = exp.concat @with_options[1..-1]
    end
    return unless exp.node_type == :hash

    hash_iterate(exp) do |option, value|
      case option[1]
      when :controller, :requirements, :singular, :path_prefix, :as,
        :path_names, :shallow, :name_prefix, :member_path, :nested_member_path
        #should be able to skip
      when :collection, :member, :new
        process_collection value
      when :has_one
        save_controller = current_controller
        process_resource value[1..-1] #Verify this is proper behavior
        self.current_controller = save_controller
      when :has_many
        save_controller = current_controller
        process_resources value[1..-1]
        self.current_controller = save_controller
      when :only
        process_option_only value
      when :except
        process_option_except value
      else
        Brakeman.notify "[Notice] Unhandled resource option: #{option}"
      end
    end
  end

  #Process route option :only => ...
  def process_option_only exp
    routes = @tracker.routes[@current_controller]
    [:index, :new, :create, :show, :edit, :update, :destroy].each do |r|
      routes.delete r
    end

    if exp.node_type == :array
      exp[1..-1].each do |e|
        routes << e[1]
      end
    end
  end

  #Process route option :except => ...
  def process_option_except exp
    return unless exp.node_type == :array
    routes = @tracker.routes[@current_controller]

    exp[1..-1].each do |e|
      routes.delete e[1]
    end
  end

  #  map.resource :x, ..
  def process_resource exp
    controller = check_for_controller_name exp
    if controller
      self.current_controller = controller
      process_resource_options exp[-1]
    else
      exp.each do |argument|
        if sexp? argument and argument.node_type == :lit
          self.current_controller = pluralize(exp[0][1].to_s)
          add_resource_routes
          process_resource_options exp[-1]
        end
      end
    end
  end

  #Process
  # map.connect '/something', :controller => 'blah', :action => 'whatever'
  def process_connect exp
    controller = check_for_controller_name exp
    self.current_controller = controller if controller
    
    #Check for default route
    if string? exp[0]
      if exp[0][1] == ":controller/:action/:id"
        @tracker.routes[:allow_all_actions] = exp[0]
      elsif exp[0][1].include? ":action"
        @tracker.routes[@current_controller] = [:allow_all_actions, exp.line]
        return
      end
    end

    #This -seems- redundant, but people might connect actions
    #to a controller which already allows them all
    return if @tracker.routes[@current_controller].is_a? Array and @tracker.routes[@current_controller][0] == :allow_all_actions
  
    exp[-1].each_with_index do |e,i|
      if symbol? e and e[1] == :action
        @tracker.routes[@current_controller] << exp[-1][i + 1][1].to_sym
        return
      end
    end
  end

  # map.with_options :controller => 'something' do |something|
  #   something.resources :blah
  # end
  def process_with_options exp
    @with_options = exp[1][3][-1]
    @nested = Sexp.new(:lvar, exp[2][1])

    self.current_controller = check_for_controller_name exp[1][3]
    
    #process block
    process exp[3] 

    @with_options = nil
    @nested = nil
  end

  # map.namespace :something do |something|
  #   something.resources :blah
  # end
  def process_namespace exp
    call = exp[1]
    formal_args = exp[2]
    block = exp[3]

    @prefix << camelize(call[3][1][1])

    @nested = Sexp.new(:lvar, formal_args[1])

    process block

    @prefix.pop
  end

  # map.something_abnormal '/blah', :controller => 'something', :action => 'wohoo'
  def process_named_route exp
    process_connect exp
  end

  #Process collection option
  # :collection => { :some_action => :http_actions }
  def process_collection exp
    return unless exp.node_type == :hash
    routes = @tracker.routes[@current_controller]

    hash_iterate(exp) do |action, type|
      routes << action[1]
    end
  end

  private

  #Checks an argument list for a hash that has a key :controller.
  #If it does, returns the value.
  #
  #Otherwise, returns nil.
  def check_for_controller_name args
    args.each do |a|
      if hash? a
        hash_iterate(a) do |k, v|
          if k[1] == :controller
            return v[1]
          end 
        end
      end
    end

    nil
  end
end

#This is for a really specific case where a hash is used as arguments
#to one of the map methods.
class Brakeman::RouteAliasProcessor < Brakeman::AliasProcessor
  
  #This replaces
  # { :some => :hash }.keys
  #with 
  # [:some]
  def process_call exp
    process_default exp
    
    if hash? exp[1] and exp[2] == :keys
        keys = get_keys exp[1] 
      exp.clear
      keys.each_with_index do |e,i|
        exp[i] = e
      end
    end
    exp
  end

  #Returns an array Sexp containing the keys from the hash
  def get_keys hash
    keys = Sexp.new(:array)
    hash_iterate(hash) do |key, value|
      keys << key
    end

    keys
  end
end
