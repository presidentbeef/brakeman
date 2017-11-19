class JustAClass
  def do_sql_stuff
    joins("INNER JOIN things ON id = #{params[:id]}").
    joins("INNER JOIN things ON stuff = 1")
  end

  def divide_by_zero
    whatever / 0 # warns

    x = 100
    y = x - 100
    z = x / y # warns

    1.0 / 0 # does not warn
  end

  def tempfile
    FileUtils.move(params.permit(:my_upload => ([:upload])).dig("my_upload", "upload").tempfile.path, "/tmp/new_temp_file")
    FileUtils.move(params.permit(:my_upload => ([:upload])).dig("my_upload", "upload").path, "/tmp/new_temp_file")
  end
end
