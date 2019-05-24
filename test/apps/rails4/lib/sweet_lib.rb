class SweetLib
  def do_some_cool_stuff bad
    `ls #{bad}`
  end

  def test_command_injection_in_lib
    IO.popen(['ls', params[:id]]) #Should not warn
    system("rm #{@bad}") #Should warn about command injection
  end

  def test_net_http_start_ssl
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE)
  end

  def external_check_test
    call_shady_method(params[:x])
  end
end
