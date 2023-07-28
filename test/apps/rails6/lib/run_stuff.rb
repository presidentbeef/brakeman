class RunStuff
  def run
    Tempfile.open("cool_stuff.txt") do |temp_file|
      `cat #{temp_file.path}`
    end
  end

  RUN_THINGS = {
    SOME_CONSTANT => "ASafeString"
  }

  def use_group_things
    RUN_THINGS[params[:key]].constantize.new
  end
end
