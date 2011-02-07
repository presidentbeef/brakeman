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
    when :root
      process_root exp
    when :member
      process_member exp
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
    when :resources
      process_resource_block exp
    when :scope
      process_scope exp
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

    elsif sexp[4][1..-1].all? { s | symbol? s }
      sexp[4][1..-1].each do |s|
        current_controller = s[1]
        add_resources_routes
      end
    end
  end
end
