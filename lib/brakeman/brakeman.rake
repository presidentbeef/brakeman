namespace :brakeman do

  desc "Run Brakeman"
  task :run, :output_file do |t, args|
    require 'brakeman'

    tracker = Brakeman.run :app_path => ".", :output_file => args[:output_file]

    if args[:output_file].nil?
      puts tracker.report
    end
  end
end
