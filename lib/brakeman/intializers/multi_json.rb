#MultiJson interface changed in 1.3.0, but need
#to support older MultiJson for Rails 3.1.
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

