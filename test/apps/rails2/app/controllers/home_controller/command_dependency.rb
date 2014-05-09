class HomeController

  def test_command2
    `ls #{params[:file_name]}`

    system params[:user_input]
  end
end
