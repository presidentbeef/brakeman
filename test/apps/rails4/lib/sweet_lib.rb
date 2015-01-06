class SweetLib
  def do_some_cool_stuff bad
    `ls #{bad}`
  end

  def test_find_group
    #Should warn, no escaping done for :group
    User.find(:all, :conditions => "title = 'blah'", :group => "something, #{params[:group]}")
  end
end
