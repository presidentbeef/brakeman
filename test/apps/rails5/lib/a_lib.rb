class JustAClass
  def do_sql_stuff
    joins("INNER JOIN things ON id = #{params[:id]}").
    joins("INNER JOIN things ON stuff = 1")
  end
end
