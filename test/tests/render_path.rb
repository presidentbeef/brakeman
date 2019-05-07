require_relative '../test'

class RenderPathTests < Minitest::Test
  def setup
    @r = Brakeman::RenderPath.new
    @at = BrakemanTester.new_tracker.app_tree
  end

  def fp path
    @at.file_path path
  end

  def test_include_controller
    @r.add_controller_render :TestController, :test, 1, fp('app/controllers/test_controller.rb')

    assert @r.include_controller? :TestController
  end

  def test_rendered_from_controller
    @r.add_controller_render :TestController, :test, 1, fp('app/controllers/test_controller.rb')

    assert @r.rendered_from_controller?
  end

  def test_include_template
    @r.add_template_render 'some/template', 1, fp('app/views/some/template.html.erb')

    assert @r.include_template? :'some/template'
  end

  def test_include_any_method
    @r.add_controller_render :TestController, :test, 10, fp('app/controllers/test_controller.rb')
    @r.add_controller_render :TestController, :test2, 20, fp('app/controllers/test_controller.rb')
    @r.add_controller_render :TestController, :test3, 30, fp('app/controllers/test_controller.rb')

    assert @r.include_any_method? ['test']
  end

  def test_each
    @r.add_controller_render :TestController, :test, 1, fp('app/controllers/test_controller.rb')
    @r.add_template_render 'some/template', 2, fp('app/views/some/template.html.erb')

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
    @r.add_controller_render :TestController, :test, 1, fp('app/controllers/test_controller.rb')

    s = @r.dup
    s.add_template_render 'some/template', 2, fp('app/views/some/template.html.erb')

    assert_equal 1, @r.length
    assert_equal 2, s.length
  end

  def test_with_relative_paths
    @r.add_controller_render :TestController, :test, 1, fp('app/controllers/test_controller.rb')
    @r.add_template_render 'some/template', 2, fp('app/views/some/template.html.erb')

    @r.with_relative_paths.each do |loc|
      assert_relative loc[:file]

      if loc[:rendered]
        assert_relative loc[:rendered][:file]
      end
    end
  end

  private

  def assert_relative path
    assert Pathname.new(path).relative?, "#{path} is not relative"
  end
end
