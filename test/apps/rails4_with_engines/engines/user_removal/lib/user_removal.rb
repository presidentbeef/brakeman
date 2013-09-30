module UserRemoval
  class Engine < Rails::Engine

    initializer :assets do |config|
      Rails.application.config.assets.precompile += Dir.glob(root.join('app/assets/stylesheets/**/*.css*')).collect {|f| f.gsub(%r{.*/app/assets/stylesheets/}, "").gsub(/\.css.*/, '.css') }
      Rails.application.config.assets.precompile += Dir.glob(root.join('app/assets/javascripts/**/*.js')).collect {|f| f.gsub(%r{.*/app/assets/javascripts/}, "") }
    end
  end
end
