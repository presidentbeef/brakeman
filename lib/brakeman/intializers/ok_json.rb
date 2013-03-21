#This is so OkJson will work with symbol values
if mj_engine == :ok_json
  class Symbol
    def to_json
      self.to_s.inspect
    end
  end
end

