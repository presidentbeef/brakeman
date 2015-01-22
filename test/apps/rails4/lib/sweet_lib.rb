class SweetLib
  def do_some_cool_stuff bad
    `ls #{bad}`
  end

  def test_command_injection_in_lib
    #Should warn about command injection
    system("rm #{@bad}")
  end
end
