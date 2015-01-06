class SweetLib
  def do_some_cool_stuff bad
    `ls #{bad}`
  end

  def test_find_group
    #Should warn, no escaping done for :group
    system("rm #{@bad}")
  end
end
