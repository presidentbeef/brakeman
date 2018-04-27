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
end
