class BeforeController < ApplicationController
  before_filter :filter1
  before_filter :filter2
  before_filter :filter3, :only => [:use_filter3, :use_filter12345]
  prepend_before_filter :filter4, :only => [:use_filter12345]
  append_before_filter :filter5, :only => [:use_filter12345]

  def use_filters12
  end

  def use_filter123
  end

  def use_filter12345
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

  def filter4
    @user = params[:user][:name] #overwritten in other filters
    @query = params[:search]
    @bill = something_else
  end
  
  def filter5
    @purchase = @account.purchases.last
  end

  include ControllerFilter
end
