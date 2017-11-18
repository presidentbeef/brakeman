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
end
