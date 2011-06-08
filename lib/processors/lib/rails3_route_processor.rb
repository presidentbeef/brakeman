#Processes the Sexp from routes.rb. Stores results in tracker.routes.
#
#Note that it is only interested in determining what methods on which
#controllers are used as routes, not the generated URLs for routes.
class RoutesProcessor < BaseProcessor
  include RouteHelper

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

    hash_iterate args[0] do |k, v|
      if symbol? k and k[1] == :to
        controller, action = extract_action v[1]

        self.current_controller = controller
        @tracker.routes[@current_controller] << action.to_sym

        break
      end
    end

    exp
  end

  def process_match exp
    args = exp[3][1..-1]

    hash_iterate args[0] do |k, v|
      if string? k and string? v
        controller, action = extract_action v[1]

        self.current_controller = controller
        @tracker.routes[@current_controller] << action.to_sym if action
      elsif symbol? k and k[1] == :action
        @tracker.routes[@current_controller] << v[1].to_sym
      end
    end

    exp
  end

  def process_verb exp
    args = exp[3][1..-1]

    if symbol? args[0]
      @tracker.routes[@current_controller] << args[0][1]
    elsif hash? args[1]
      hash_iterate args[1] do |k, v|
        if symbol? k and k[1] == :to and string? v
          controller, action = extract_action v[1]

          self.current_controller = controller
          @tracker.routes[@current_controller] << action.to_sym
        end
      end
    elsif string? args[0]
      route = args[0][1].split "/"
      if route.length != 2
        @tracker.routes[@current_controller] << route[0].to_sym
      else
        self.current_controller = route[0]
        @tracker.routes[@current_controller] << route[1].to_sym
        @current_controller = nil
      end
    else hash? args[0]
      hash_iterate args[0] do |k, v|
        if string? v
          controller, action = extract_action v[1]

          self.current_controller = controller
          @tracker.routes[@current_controller] << action.to_sym
        end
      end
    end

    exp
  end

  def process_resources exp
    if exp[3] and exp[3][2] and exp[3][2][0] == :hash
      #handle hash
    elsif exp[3][1..-1].all? { |s| symbol? s }
      exp[3][1..-1].each do |s|
        self.current_controller = s[1]
        add_resources_routes
      end
    end

    exp
  end

  def process_resource exp
    exp[3][1..-1].each do |s|
      self.current_controller = s[1]
      add_resource_routes
    end

    exp
  end

  def process_resources_block exp
    process_resources exp[1]
    process exp[3]
    exp
  end

  def process_resource_block exp
    process_resource exp[1]
    process exp[3]
    exp
  end

  def process_scope_block exp
    #How to deal with options?
    process exp[3]
    exp
  end

  def extract_action str
    str.split "#"
  end
end
