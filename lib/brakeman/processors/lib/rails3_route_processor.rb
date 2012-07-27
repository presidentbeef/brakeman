#Processes the Sexp from routes.rb. Stores results in tracker.routes.
#
#Note that it is only interested in determining what methods on which
#controllers are used as routes, not the generated URLs for routes.
class Brakeman::Rails3RoutesProcessor < Brakeman::BaseProcessor
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

  def process_routes exp
    process exp.dup
  end

  def process_call exp
    case exp.method
    when :resources
      process_resources exp
    when :resource
      process_resource exp
    when :root
      process_root exp
    when :member
      process_default exp
    when :get, :put, :post, :delete
      process_verb exp
    when :match
      process_match exp
    else
      exp
    end
  end

  def process_iter exp
    case exp.block_call.method
    when :namespace
      process_namespace exp
    when :resource
      process_resource_block exp
    when :resources
      process_resources_block exp
    when :scope
      process_scope_block exp
    else
      super
    end
  end

  def process_namespace exp
    name = exp.block_call.first_arg.value
    block = exp.block

    @prefix << camelize(name)

    process block

    @prefix.pop

    exp
  end

  #TODO: Need test for this
  def process_root exp
    args = exp.args

    if value = hash_access(args.first, :to)
      if string? value
        controller, action = extract_action value.value

        add_route action, controller
      end
    end

    exp
  end

  def process_match exp
    args = exp.args

    #Check if there is an unrestricted action parameter
    action_variable = false

    if string? args.first
      matcher = args.first.value

      if matcher == ':controller(/:action(/:id(.:format)))' or
        matcher.include? ':controller' and matcher.include? ':action' #Default routes
        @tracker.routes[:allow_all_actions] = args.first
        return exp
      elsif matcher.include? ':action'
        action_variable = true
      end
    end

    if hash? args.last
      hash_iterate args.last do |k, v|
        if string? k and string? v
          controller, action = extract_action v.value

          add_route action if action
        elsif symbol? k and k.value == :action
          add_route action
          action_variable = false
        end
      end
    end

    if action_variable
      @tracker.routes[@current_controller] = :allow_all_actions
    end

    exp
  end

  def process_verb exp
    args = exp.args
    first_arg = args.first

    if symbol? first_arg and not hash? args.second
      add_route first_arg
    elsif hash? args.second
      hash_iterate args.second do |k, v|
        if symbol? k and k.value == :to and string? v
          controller, action = extract_action v.value

          add_route action, controller
        end
      end
    elsif string? first_arg
      route = first_arg.value.split "/"
      if route.length != 2
        add_route route[0]
      else
        add_route route[1], route[0]
        @current_controller = nil
      end
    else hash? first_arg
      hash_iterate first_arg do |k, v|
        if string? v
          controller, action = extract_action v.value

          add_route action, controller
          break
        end
      end
    end

    exp
  end

  def process_resources exp
    if exp.args and exp.args.second and exp.args.second.node_type == :hash
      self.current_controller = exp.first_arg.value
      #handle hash
      add_resources_routes
    elsif exp.args.all? { |s| symbol? s }
      exp.args.each do |s|
        self.current_controller = s.value
        add_resources_routes
      end
    end

    exp
  end

  def process_resource exp
    #Does resource even take more than one controller name?
    exp.args.each do |s|
      if symbol? s
        self.current_controller = pluralize(s.value.to_s)
        add_resource_routes
      else
        #handle something else, like options
        #or something?
      end
    end

    exp
  end

  def process_resources_block exp
    process_resources exp.block_call
    process exp.block
    exp
  end

  alias process_resource_block process_resources_block

  def process_scope_block exp
    #How to deal with options?
    process exp.block
    exp
  end

  def extract_action str
    str.split "#"
  end
end
