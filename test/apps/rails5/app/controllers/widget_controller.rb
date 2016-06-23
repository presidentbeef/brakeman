class WidgetController < ApplicationController
  def show
  end

  def dynamic_constant
    identifier_class = params[:IdentifierClass]
    namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE # should warn
  end

  def render_thing
    render params[:x].thing?
  end
end

IDENTIFIER_NAMESPACE = 'apis'
