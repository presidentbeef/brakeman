class RunStuff
  def run
    Tempfile.open("cool_stuff.txt") do |temp_file|
      `cat #{temp_file.path}`
    end
  end
end
