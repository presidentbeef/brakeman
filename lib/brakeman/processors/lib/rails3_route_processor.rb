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
    @controller_block = false
  end

  def process_routes exp
    process exp.dup
  end

  def process_call exp
    case exp[2]
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
    case exp[1][2]
    when :namespace
      process_namespace exp
    when :resource
      process_resource_block exp
    when :resources
      process_resources_block exp
    when :scope
      process_scope_block exp
    when :controller
      process_controller_block exp
    else
      super
    end
  end

  def process_namespace exp
    name = exp[1][3][1][1]
    block = exp[3]

    @prefix << camelize(name)

    process block

    @prefix.pop

    exp
  end

  def process_root exp
    args = exp[3][1..-1]

    if value = hash_access(args[0], :to)
      if string? value
        add_route_from_string value
      end
    end

    exp
  end

  def process_match exp
    args = exp[3][1..-1]

    #Check if there is an unrestricted action parameter
    action_variable = false

    if string? args[0]
      matcher = args[0][1]

      if matcher == ':controller(/:action(/:id(.:format)))' or
        matcher.include? ':controller' and matcher.include? ':action' #Default routes
        @tracker.routes[:allow_all_actions] = args[0]
        return exp
      elsif matcher.include? ':action'
        action_variable = true
      elsif args[1].nil? and in_controller_block? and not matcher.include? ":"
        add_route matcher
      end
    end

    if hash? args[-1]
      hash_iterate args[-1] do |k, v|
        if string? k
          if string? v
            add_route_from_string v[1]
          elsif in_controller_block? and symbol? v
            add_route v
          end
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

  def add_route_from_string value
    value = value[1] if string? value

    controller, action = extract_action value

    if action
      add_route action, controller
    elsif in_controller_block?
      add_route value
    end
  end

  def process_verb exp
    args = exp[3][1..-1]

    if symbol? args[0] and not hash? args[1]
      add_route args[0]
    elsif hash? args[1]
      hash_iterate args[1] do |k, v|
        if symbol? k and k[1] == :to
          if string? v
            add_route_from_string v[1]
          elsif in_controller_block? and symbol? v
            add_route v
          end
        end
      end
    elsif string? args[0]
      route = args[0][1].split "/"
      if route.length != 2
        add_route route[0]
      else
        add_route route[1], route[0]
        @current_controller = nil
      end
    elsif in_controller_block? and symbol? args[0]
      add_route args[0]
    else hash? args[0]
      hash_iterate args[0] do |k, v|
        if string? k
          if string? v
            controller, action = extract_action v[1]

            if action
              add_route action, controller
              break
            elsif in_controller_block?
              add_route v
            end
          elsif in_controller_block?
            add_route v
          end
        end
      end
    end

    exp
  end

  def process_resources exp
    if exp[3] and exp[3][2] and exp[3][2][0] == :hash
      self.current_controller = exp[3][1][1]
      #handle hash
      add_resources_routes
    elsif exp[3][1..-1].all? { |s| symbol? s }
      exp[3][1..-1].each do |s|
        self.current_controller = s[1]
        add_resources_routes
      end
    end

    exp
  end

  def process_resource exp
    #Does resource even take more than one controller name?
    exp[3][1..-1].each do |s|
      if symbol? s
        self.current_controller = pluralize(s[1].to_s)
        add_resource_routes
      else
        #handle something else, like options
        #or something?
      end
    end

    exp
  end

  def process_resources_block exp
    process_resources exp[1]

    in_controller_block do
      process exp[3]
    end

    exp
  end

  def process_resource_block exp
    process_resource exp[1]

    in_controller_block do
      process exp[3]
    end

    exp
  end

  def process_scope_block exp
    #How to deal with options?
    process exp[3]
    exp
  end

  def process_controller_block exp
    args = exp[1][3]
    self.current_controller = args[1][1]

    in_controller_block do
      process exp[-1] if exp[-1]
    end

    exp
  end

  def extract_action str
    str.split "#"
  end

  def in_controller_block?
    @controller_block
  end

  def in_controller_block
    prev_block = @controller_block
    @controller_block = true
    yield
    @controller_block = prev_block
  end
end
