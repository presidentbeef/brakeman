class FileController < ApplicationController
  def download_tempfile_with_params
    send_file Tempfile.new([params[:file_name], ".txt"])
  end

  def download_sanitized_with_params
    send_file ActiveStorage::Filename.new("#{params[:file_name]}.jpg").sanitized
  end
end
