class RemovalController < ApplicationController
  def change_lines
    <<-X
    this
    method
    is
    here
    for line
    numbers
    X
  end

  def remove_this
    redirect_to params[:url]
  end

  def remove_this_too
    @some_input = raw params[:input]
    @some_other_input = Account.first.name

    render 'removal/controller_removed'
  end
end
