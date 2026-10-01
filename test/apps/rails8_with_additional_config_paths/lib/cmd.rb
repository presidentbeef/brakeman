class Cmd
  def diff
    diff_output, _error, _status = Open3.capture3('git', 'diff', 'origin/main', "origin/#{release_branch}".shellescape)
  end
end
