#MultiJson interface changed in 1.3.0, but need
#to support older MultiJson for Rails 3.1.
mj_engine = nil

if MultiJson.respond_to? :default_adapter
  mj_engine = MultiJson.default_adapter
else
  mj_engine = MultiJson.default_engine

  module MultiJson
    def self.dump *args
      encode *args
    end

    def self.load *args
      decode *args
    end
  end
end

#This is so OkJson will work with symbol values
if mj_engine == :ok_json
  class Symbol
    def to_json
      self.to_s.inspect
    end
  end
end

