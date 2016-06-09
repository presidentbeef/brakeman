class WidgetController < ApplicationController
  def show
  end

  def dynamic_constant
    identifier_class = params[:IdentifierClass]
    namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE # should warn
  end
end

IDENTIFIER_NAMESPACE = 'apis'
