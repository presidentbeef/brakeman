class Notifier < ActionMailer::Base
  def nsfree_deactivation_heroku(account, allowed, used)
    # ...   
    subject "#{Zerigo.service_provider[:company_name]} add-on at Heroku: #{Zerigo.sites[:ns][:app_name]} service deactivated"
    from Zerigo.service_provider[:company_support_email]
    recipients rcpts
    bcc Zerigo.service_provider[:company_bcc_email]
    sent_on Time.now

    body :allowed => allowed, :used => used, :account => account
  end
end
