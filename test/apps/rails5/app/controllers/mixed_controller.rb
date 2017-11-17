class BaseController < ActionController::Base
  # No protect_from_forgery call, but one mixed in
  include ForgeryProtection
  include Concerning

  Statistics::AdminWithdrawal::BANK_LIST = [:deutsche, :boa, :jpm_chase, :cyprus]

  def another_early_return
    bank_name = params[:filename].first
    unless Statistics::AdminWithdrawal::BANK_LIST.include?(bank_name)
      flash[:alert] = 'Invalid filename'
      redirect_to :back
      return
    end

    Statistics::AdminWithdrawal.send("export_#{bank_name}_#inc!")
  end

  def yet_another_early_return
    scope_name = params[:scope].presence
    fail ActiveRecord::RecordNotFound unless ['safe', 'also_safe'].include?(scope_name)
    Model.public_send(scope_name)
  end

  def redirect_to_strong_params
    redirect_to params.permit(:domain) # should warn
    redirect_to params.permit(:page, :sort) # should not warn
  end
end
