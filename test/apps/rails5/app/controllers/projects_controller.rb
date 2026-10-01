class ProjectsController < ApplicationController
  def show
    @project = Project.find(params[:id])
  end

  def comment
    @comment = Comment.find(params[:id])
  end
end
