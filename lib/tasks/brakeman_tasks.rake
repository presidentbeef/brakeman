require 'rake'

namespace :brakeman do
  OUTPUT_DIR = "tmp/brakeman"


  desc "Run brakeman' tests."
  task :test do
    `brakeman`
  end

  desc 'Run brakeman tests and open results in your browser.'
  task :report do
    #cleanup the environment
    rm_rf OUTPUT_DIR
    mkdir OUTPUT_DIR

    #execute brakeman
    OUTPUT_FILE = File.join(OUTPUT_DIR, "index.html")
    `brakeman -o #{OUTPUT_FILE}`

    #open the browser
    if PLATFORM['darwin']
        system("open #{OUTPUT_FILE}")
    elsif PLATFORM[/linux/]
      system("xdg-open #{OUTPUT_FILE}")
    else
      puts "You can view brakeman results at #{file}"
    end
  end

end
