module UserMixin
  def mixin_action
    @dangerous_input = params[:bad]

    render 'users/mixin_template'
  end
end
