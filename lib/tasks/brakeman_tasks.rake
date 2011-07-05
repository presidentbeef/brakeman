require 'rake'

namespace :brakeman do
  OUTPUT_DIR = "tmp/brakeman"
  TEST_DIR = "test/brakeman"


  desc "Run Brakeman's tests."
  task :test do
    `brakeman`
  end

  desc "Run Brakeman's tests and open results in your browser."
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


  desc 'Generate the initial configuration for Brakeman'
  task :setup do
    mkdir_p TEST_DIR
    templates_path = File.expand_path(File.join(File.dirname(__FILE__), "template"))
    blessed_path = File.join(templates_path, "blessed.rb")
    cp blessed_path, TEST_DIR, :verbose => true
  end

end
