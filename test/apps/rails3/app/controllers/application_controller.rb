class ApplicationController < ActionController::Base
#  protect_from_forgery
  before_filter :action_in_parent, :only => :action_in_child
end
