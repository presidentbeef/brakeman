require 'tmpdir'
require 'brakeman/rescanner'

class Brakeman::Rescanner
  #For access to internals
  attr_reader :changes, :reindex
end

class RescannerTests < Test::Unit::TestCase
  include BrakemanTester::RescanTestHelper

  def test_no_change_no_warnings
    before_rescan_of []

    assert_fixed 0
    assert_new 0
    assert_equal false, rescan.warnings_changed?
  end

  def test_no_change
    before_rescan_of []

    assert rescan.any_warnings?
    assert_reindex :none
    assert_changes false
    assert_fixed 0
    assert_new 0
  end

  def test_irrelavent_new_file
    before_rescan_of "IRRELEVANT" do
      write_file "IRRELEVANT", "Nothing special here"
    end

    assert_reindex :none
    assert_changes false #No files were rescanned
    assert_new 0
    assert_fixed 0
  end

  def test_irrelevant_deleted_file
    before_rescan_of "README.rdoc" do
      remove "README.rdoc"
    end

    assert_reindex :none
    assert_changes false #No files were rescanned
    assert_new 0
    assert_fixed 0
  end

  def test_delete_template
    template = "app/views/users/show.html.erb"

    before_rescan_of template do
      remove template
    end

    assert_reindex :none #because deleted
    assert_changes
    assert_new 0
    assert_fixed 1
    assert_nil @original.templates[:"users/show"] #tracker is modified
  end

  def test_controller_remove_method
    controller = "app/controllers/removal_controller.rb"

    before_rescan_of controller do
      remove_method controller, :remove_this
    end

    assert_reindex :controllers, :templates 
    assert_changes
    assert_new 0
    assert_fixed 1
  end

  def test_controller_remove_method_for_line_numbers_only
    controller = "app/controllers/removal_controller.rb"

    before_rescan_of controller do
      remove_method controller, :change_lines
    end

    assert_reindex :controllers, :templates 
    assert_changes
    assert_new 0
    assert_fixed 0
  end

  def test_delete_controller
    controller = "app/controllers/removal_controller.rb"

    before_rescan_of controller do
      remove controller
    end

    assert_reindex :none
    assert_changes
    assert_new 0
    assert_fixed 4
  end

  def test_controller_escape_params
    controller = "app/controllers/users_controller.rb"

    before_rescan_of controller do
      replace controller, "@user_data = raw params[:user_data]", "@user_data = params[:user_data]"
    end

    assert_reindex :controllers, :templates
    assert_changes
    assert_new 0
    assert_fixed 1
  end

  def test_template_add_line
    template = "app/views/users/show.html.erb"

    before_rescan_of template do
      append template, "<%= raw params[:bad] %>"
    end

    assert_reindex :templates
    assert_changes
    assert_new 1
    assert_fixed 0
  end

  def test_partial_template_add_line
    template = "app/views/users/_form.html.erb"

    before_rescan_of template do
      append template, "<%= raw @user.thing %>"
    end

    assert_reindex :templates
    assert_changes
    assert_new 1
    assert_fixed 0
  end

  def test_delete_model
    model = "app/models/user.rb"

    before_rescan_of model do
      remove model
    end

    assert_reindex :templates, :models, :controllers
    assert_changes
    assert_new 7 #User is no longer a model, causing MORE warnings
    assert_fixed 7
  end

  def test_add_method_to_model
    model = "app/models/user.rb"

    before_rescan_of model do
      add_method model, <<-'RUBY'
      def bad_sql input
        find(:all, :conditions => "x > #{input}")
      end
      RUBY
    end
      
    assert_reindex :models
    assert_changes
    assert_new 1
    assert_fixed 0
  end

  def test_change_config
    config = "config/environments/production.rb"

    before_rescan_of config do
      replace config, "config.active_record.whitelist_attributes = true",
        "config.active_record.whitelist_attributes = false"
    end

    assert_reindex :none
    assert_changes 
    assert_new 1
    assert_fixed 0
  end

  def test_remove_route
    routes = "config/routes.rb"

    before_rescan_of routes, "rails3.2", :assume_all_routes => false do
      replace routes, "match 'implicit' => 'removal#implicit_render'", ""
    end

    assert_reindex :controllers, :templates
    assert_changes
    assert_new 0
    assert_fixed 1
  end

  def test_remove_initializer
    #Should probably remove initializer that actually affects something
    initializer = "config/initializers/wrap_parameters.rb"

    before_rescan_of initializer do
      remove initializer
    end

    assert_reindex :none
    assert_changes
    assert_new 0
    assert_fixed 0
  end

  def test_remove_mixin
    lib = 'lib/user_controller_mixin.rb'

    before_rescan_of lib do
      remove lib
    end

    assert_reindex :controllers, :templates
    assert_changes
    assert_new 0
    assert_fixed 1
  end

  def test_remove_route_from_mixin
    lib = 'lib/user_controller_mixin.rb'

    before_rescan_of lib do
      remove_method lib, :mixed_in
    end

    assert_reindex :controllers, :templates
    assert_changes
    assert_new 0
    assert_fixed 1
  end

  def test_gemfile_rails_version_change
    gemfile = "Gemfile.lock"

    before_rescan_of gemfile do
      replace gemfile, "rails (3.2.9.rc2)", "rails (3.2.6)"
    end

    #@original is actually modified
    assert @original.config[:rails_version], "3.2.6"
    assert_reindex :none
    assert_changes
    assert_new 1
    assert_fixed 0
  end
end
