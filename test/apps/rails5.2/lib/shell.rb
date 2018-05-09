class ShellStuff
  def initialize(one, two)
    @one = Shellwords.shellescape(one)
    @two = Shellwords.escape(two)
  end

  def run(ip)
    ip = Shellwords.shellescape(ip)
    `dig +short -x #{ip} @#{@one} -p #{@two}`
  end

  def backticks_target(path)
    `echo #{path}`.chomp
  end

  def process_pid
    # should not warn
    `something #{Process.pid}`
  end

  def nested_system_interp
    filename = Shellwords.escape("#{file_prefix}.txt")
    system "echo #{filename}"
  end

  def system_array_join
    command = ["ruby", method_that_returns_user_input, "--some-flag"].join(" ")
    system(command)
  end

  def system_as_target
    !system("echo #{foo}")
  end
end
