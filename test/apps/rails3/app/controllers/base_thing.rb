class BaseThing < ApplicationController
  def action_in_parent
    @from_parent = params[:horrible_thing]
  end
end
