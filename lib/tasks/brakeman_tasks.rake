require 'rake'

namespace :brakeman do

  desc "Run brakeman' tests."
  task :test do
    rm_rf "tmp/brakeman"
    Rake::Task.new(:brakeman_test) do |t|
        `brakeman`
    end

    Rake::Task[:brakeman_test].invoke
  end

  desc 'Run brakeman tests and open results in your browser.'
  task :report do
    begin
      Rake::Task['brakeman:test'].invoke
    rescue RuntimeError => e
      puts e.message
    end

    Dir.glob("tmp/brakeman/**/index.html") do |file|
      if PLATFORM['darwin']
        system("open #{file}")
      elsif PLATFORM[/linux/]
        system("xdg-open #{file}")
      else
        puts "You can view brakeman results at #{file}"
      end
    end
  end

end
