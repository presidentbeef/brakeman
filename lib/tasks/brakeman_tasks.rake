require 'rake'
require 'brakeman'

namespace :brakeman do

  OUTPUT_DIR = "tmp/brakeman"
  OUTPUT_FILE = File.join(OUTPUT_DIR, "index.html")
  TEST_DIR = "test/brakeman"


  def brakeman_run(options={})
      options[:app_path] = ::Rails.root.to_s unless options.has_key? :app_path
      puts options[:app_path]
      Brakeman.main options
  end



  desc "Run Brakeman's tests."
  task :test do
      warnings_num = brakeman_run
      if warnings_num > 0
          puts "Brakeman found #{warnings_num} potential issues. An exception will now be raised, for continuous integration."
          raise Exception
      end
  end



  desc "Run Brakeman's tests generating the html."
  task :report do
    #cleanup the environment
    rm_rf OUTPUT_DIR
    mkdir OUTPUT_DIR

    #execute brakeman
    options = {:output_file => OUTPUT_FILE}
    warnings_num = brakeman_run options
    if warnings_num > 0
      puts "Brakeman found #{warnings_num} potential issues. An exception will now be raised, for continuous integration."
      raise Exception
    end
  end



  desc "Run Brakeman's tests and open results in your browser."
  task :report_browser do
    begin
        Rake::Task['tarantula:test'].invoke
    rescue Exception
    end
    #open the browser
    if PLATFORM['darwin']
      system("open #{OUTPUT_FILE}")
      puts "Opening Brakeman's report in the default browser"
    elsif PLATFORM[/linux/]
      system("xdg-open #{OUTPUT_FILE}")
      puts "Opening Brakeman's report in the default browser"
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
