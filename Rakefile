require 'rake'

begin
    require 'jeweler'
    files = ["CHANGES", "LICENSE", "Rakefile", "FEATURES", "README.md",  "WARNING_TYPES"]
    files << Dir["bin/*", "lib/**/*.rb", "lib/format/*.css"]

    Jeweler::Tasks.new do |s|
        s.name = %q{brakeman}
        s.authors = ["Justin Collins", "Luca Invernizzi"]
        s.email = ["", "invernizzi.l@gmail.com"]
        s.summary = "Security vulnerability scanner for Ruby on Rails."
        s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis."
        s.homepage = "http://github.com/invernizzi/brakeman"
        s.executables = ["brakeman"]
        s.require_paths = ["lib"]
        s.files = files.flatten
        s.add_dependency "activesupport", ">= 2.2"
        s.add_dependency "ruby2ruby", ">= 1.2.4" 
        s.add_dependency "ruport", ">= 1.6.3"
        s.add_dependency "erubis", ">= 2.6.5"
        s.add_dependency "haml", ">= 3.0.12"
    end
    Jeweler::GemcutterTasks.new
rescue LoadError
    puts "Jeweler not available. Install it with: gem install jeweler"
end

