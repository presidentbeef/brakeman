module Brakeman
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'brakeman/brakeman.rake'
    end
  end
end
