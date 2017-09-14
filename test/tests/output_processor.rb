require_relative '../test'

class OutputProcessorTests < Minitest::Test
  def assert_output expected, original
    output = Brakeman::OutputProcessor.new.format original

    assert_equal expected, output
  end

  def test_output_nil
    assert_output "[Format Error]", nil
  end

  def test_output_empty_sexp
    assert_output "[Format Error]", Sexp.new
  end

  def test_output_missing_node_type
    assert_output "[Format Error]", Sexp.new(Sexp.new(:str, 'x'))
  end

  def test_output_bad_node_type
    assert_output "[Format Error]", Sexp.new(:bad_node_type)
  end

  def test_output_local_variable
    assert_output "x", Sexp.new(:lvar, :x)
  end

  def test_output_ignore
    assert_output "[ignored]", Sexp.new(:ignore, :whatever)
  end

  def test_output_params
    assert_output "params", Sexp.new(:params, :anything)
  end

  def test_output_session
    assert_output "session", Sexp.new(:session)
  end

  def test_output_cookies
    assert_output "cookies[:yum]", Sexp.new(:call,
                                            Sexp.new(:cookies),
                                            :[],
                                            Sexp.new(:arglist,
                                                     Sexp.new(:lit, :yum)))
  end

  def test_output_output
    assert_output "[Output] x", Sexp.new(:output,
                                         Sexp.new(:lvar, :x))
  end

  def test_output_output_format
    assert_output "", Sexp.new(:output,
                               Sexp.new(:format, Sexp.new(:str, 'bye')))
  end

  def test_output_escaped_output
    assert_output '[Escaped Output] @x', Sexp.new(:escaped_output,
                                                   Sexp.new(:ivar, :@x))
  end

  def test_output_string_output
    assert_output '', Sexp.new(:output, Sexp.new(:str, 'x'))
    assert_output '', Sexp.new(:escaped_output, Sexp.new(:str, 'x'))
  end

  def test_output_format_string_literal
    assert_output "", Sexp.new(:output,
                               Sexp.new(:format, Sexp.new(:str, 'hi')))

  end

  def test_output_escaped_format_string_literal
    assert_output "", Sexp.new(:escaped_output,
                               Sexp.new(:format, Sexp.new(:str, 'hi')))

  end


  def test_output_string_interp
    assert_output '"#{@x}"', Sexp.new(:dstr,
                                      "",
                                      Sexp.new(:evstr,
                                               Sexp.new(:ivar, :@x)))

    input = '"#{params[:plugin]}/app/views/#{params[:view]}"'
    s_input = RubyParser.new.parse(input)

    assert_output input,
      Brakeman::BaseProcessor.new(nil).process(s_input)
  end

  def test_output_format
    assert_output "[Format] @x", Sexp.new(:format, Sexp.new(:ivar, :@x))
  end

  def test_output_format_escaped
    assert_output "[Escaped] @x", Sexp.new(:format_escaped,
                                            Sexp.new(:ivar, :@x))
  end

  def test_output_format_escaped_string_literal
    assert_output "", Sexp.new(:format_escaped, Sexp.new(:str, "hi"))
  end

  def test_output_format_escaped_with_escaped_literal
    assert_output "", Sexp.new(:format_escaped,
                               Sexp.new(:escaped_output, Sexp.new(:str, 'hi')))
  end


  def test_format_string_literal
    assert_output "", Sexp.new(:format, Sexp.new(:str, "hi"))
  end

  def test_output_format_escaped_literal
    assert_output "", Sexp.new(:format,
                               Sexp.new(:escaped_output, Sexp.new(:str, 'hi')))
  end

  def test_output_unknown_model
    assert_output "(Unresolved Model)", Sexp.new(:const,
                                                 Brakeman::Tracker::UNKNOWN_MODEL)
  end

  def test_output_render
    assert_output 'render(partial => "x/y", { :locals => ({ :user => (@user) }) })',
      Sexp.new(:render,
               :partial,
               Sexp.new(:str, "x/y"),
               Sexp.new(:hash, 
                        Sexp.new(:lit, :locals),
                        Sexp.new(:hash,
                                 Sexp.new(:lit, :user),
                                 Sexp.new(:ivar, :@user))))
  end

  def test_output_rlist
    assert_output "a\nb",
      Sexp.new(:rlist,
               Sexp.new(:call, nil, :a, Sexp.new(:arglist)),
               Sexp.new(:call, nil, :b, Sexp.new(:arglist)))
  end

  def test_output_call_with_block
    assert_output "x do\n y\n end",
      Sexp.new(:iter,
               Sexp.new(:call, nil, :x),
               Sexp.new(:args),
               Sexp.new(:call, nil, :y))
  end

  # Ruby2Ruby tries to convert some methods to attr_* calls,
  # but it breaks some stuff because of how it accesses nodes.
  # So we overwrite it.
  def test_output_defn_not_attr
    assert_output "def x\n  @x\nend",
      Sexp.new(:defn,
               :x,
               Sexp.new(:args),
               Sexp.new(:ivar, :@x))

    assert_output "def x(y)\n  @x = y\nend",
      Sexp.new(:defn,
               :x,
               Sexp.new(:args, :y),
               Sexp.new(:iasgn, :@x, Sexp.new(:lvar, :y)))
  end

  def test_regexp_output_with_flags
    assert_output '/#{x}/i',
      s(:dregx, "",
        s(:evstr,
          s(:call, nil, :x)),
          1)
  end

  def test_rescue_block
    assert_output "a rescue b",
      s(:rescue, s(:call, nil, :a),
        s(:resbody, s(:array), s(:call, nil, :b)))
  end

  def test_command_interpolation
    assert_output '`#{x}`',
      s(:dxstr, "", s(:evstr, s(:call, nil, :x)))


    input = Brakeman::BaseProcessor.new(nil).process(RubyParser.new.parse('`1#{x}2#{y}3`'))
    assert_output '`1#{x}2#{y}3`', input
  end
end
