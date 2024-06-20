module Brakeman::ErubisPatch
  # Simple patch to make `erubis` compatible with frozen string literals
  def convert(input)
    codebuf = +"" # Modified line, the rest is identitical
    @preamble.nil? ? add_preamble(codebuf) : (@preamble && (codebuf << @preamble))
    convert_input(codebuf, input)
    @postamble.nil? ? add_postamble(codebuf) : (@postamble && (codebuf << @postamble))
    @_proc = nil    # clear cached proc object
    return codebuf  # or codebuf.join()
  end
end
