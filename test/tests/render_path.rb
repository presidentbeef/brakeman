require_relative '../test'

class RenderPathTests < Minitest::Test
  def setup
    @r = Brakeman::RenderPath.new
  end

  def test_include_controller
    @r.add_controller_render :TestController, :test, 1, 'app/controllers/test_controller.rb'

    assert @r.include_controller? :TestController
  end

  def test_rendered_from_controller
    @r.add_controller_render :TestController, :test, 1, 'app/controllers/test_controller.rb'

    assert @r.rendered_from_controller?
  end

  def test_include_template
    @r.add_template_render 'some/template', 1, 'app/views/some/template.html.erb'

    assert @r.include_template? :'some/template'
  end

  def test_include_any_method
    @r.add_controller_render :TestController, :test, 10, 'app/controllers/test_controller.rb'
    @r.add_controller_render :TestController, :test2, 20, 'app/controllers/test_controller.rb'
    @r.add_controller_render :TestController, :test3, 30, 'app/controllers/test_controller.rb'

    assert @r.include_any_method? ['test']
  end

  def test_each
    @r.add_controller_render :TestController, :test, 1, 'app/controllers/test_controller.rb'
    @r.add_template_render 'some/template', 2, 'app/views/some/template.html.erb'

    @r.each do |loc|
      case loc[:type]
      when :template
        assert_equal :'some/template', loc[:name]
      when :controller
        assert_equal :TestController, loc[:class]
        assert_equal :test, loc[:method]
      end
    end
  end

  def test_dup
    @r.add_controller_render :TestController, :test, 1, 'app/controllers/test_controller.rb'

    s = @r.dup
    s.add_template_render 'some/template', 2, 'app/views/some/template.html.erb'

    assert_equal 1, @r.length
    assert_equal 2, s.length
  end
end
