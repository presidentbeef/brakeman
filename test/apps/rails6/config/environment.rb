# Load the Rails application.
require_relative 'application'

# A Dir.glob constant for testing
FILE_LIST = Dir.glob(File.join(Rails.root, "app", "views", "**", "*")).select do |f|
  f.end_with? ".html"
end

# Initialize the Rails application.
Rails.application.initialize!
