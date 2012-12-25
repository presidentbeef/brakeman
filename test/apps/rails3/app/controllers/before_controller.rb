class BeforeController < ApplicationController
  before_filter :filter1
  before_filter :filter2
  before_filter :filter3, :only => [:use_filter3]

  def use_filters12
  end

  def use_filter123
  end

  private

  def filter1
    @user = User.find(params[:user_id])
  end

  def filter2
    @bill = @user.bill
  end

  def filter3
    @account = @user.account
  end
end
