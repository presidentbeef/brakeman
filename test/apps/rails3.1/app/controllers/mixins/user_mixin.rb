module UserMixin
  #Test mixin action method with explicit template
  def mixin_action
    @dangerous_input = params[:bad]
    render 'users/mixin_template'
  end

  #Test mixin action method with default template
  def mixin_default
    @dangerous_input = params[:bad]
  end
end
