# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  before_filter :awesome

  def funky_panda
  end

  def awesome
    something = if params[:thang]
                  params[:thang]
                elsif somevar = "monkeypanda"
                  somevar = somevar.split(",").map { |s|
                    s += 'stuff' unless s =~ /regex/
                      s.split('things')
                  }.first
                  somevar.first.downcase
                end

    if (some_var = SomeClass.things, something)
      AnotherClass.thang = @thang = some_var.to_sym
    elsif (some_var = find_thang(AppConfig.stuff, something))
      AnotherClass.thang = @thang = some_var.to_sym
    end

    if beta_override && cookies['yummy'] != @thang.to_s
      cookies['yummy'] = { :value => @thang.to_s }
    end

    return true
  end

  def decent
    p = params
    if params[:thang] && self.respond_to?(params[:thang].to_sym)
      :"really_#{params[:thang]}"
    end
    p.symbolize_keys[:custom]
  end

end
