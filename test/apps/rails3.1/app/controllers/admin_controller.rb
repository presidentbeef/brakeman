class AdminController < ApplicationController
  #Examples of skipping important filters with a blacklist instead of whitelist
  skip_before_filter :login_required, :except => :do_admin_stuff
  skip_filter :authenticate_user!, :except => :do_admin_stuff
  skip_before_filter :require_user, :except => [:do_admin_stuff, :do_other_stuff]
end
