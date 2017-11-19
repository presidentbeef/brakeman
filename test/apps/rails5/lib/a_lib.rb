class JustAClass
  def do_sql_stuff
    joins("INNER JOIN things ON id = #{params[:id]}").
    joins("INNER JOIN things ON stuff = 1")
  end

  def tempfile
    FileUtils.move(params.permit(:my_upload => ([:upload])).dig("my_upload", "upload").tempfile.path, "/tmp/new_temp_file")
    FileUtils.move(params.permit(:my_upload => ([:upload])).dig("my_upload", "upload").path, "/tmp/new_temp_file")
  end
end
