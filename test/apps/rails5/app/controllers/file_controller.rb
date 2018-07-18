class FileController < ApplicationController
  def download_tempfile_with_params
    send_file Tempfile.new([params[:file_name], ".txt"])
  end
end
