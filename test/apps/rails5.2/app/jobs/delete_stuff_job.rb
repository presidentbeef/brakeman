class DeleteStuffJob < ApplicationJob
  def perform file
    `rm -rf #{file}`
  end
end
