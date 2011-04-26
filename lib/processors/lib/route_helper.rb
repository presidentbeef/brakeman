module RouteHelper
  #Manage Controller prefixes
  #@prefix is an Array, but this method returns a string
  #suitable for prefixing onto a controller name.
  def prefix
    if @prefix.length > 0
      @prefix.join("::") << "::"
    else
      ''
    end
  end

  #Sets the controller name to a proper class name.
  #For example
  # self.current_controller = :session
  # @controller == :SessionController #true
  #
  #Also prepends the prefix if there is one set.
  def current_controller= name
    @current_controller = (prefix + camelize(name) + "Controller").to_sym
    @tracker.routes[@current_controller] ||= Set.new
  end

  #Add default routes
  def add_resources_routes
    @tracker.routes[@current_controller].merge [:index, :new, :create, :show, :edit, :update, :destroy]
  end


  #Add default routes minus :index
  def add_resource_routes
    @tracker.routes[@current_controller].merge [:new, :create, :show, :edit, :update, :destroy]
  end
end
