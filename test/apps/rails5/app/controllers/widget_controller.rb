class WidgetController < ApplicationController
  def show
  end

  def dynamic_constant
    identifier_class = params[:IdentifierClass]
    namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE # should warn
  end

  def render_thing
    render params[:x].thing?
  end

  def render_inline
    render :inline => "<%= xss.html_safe %>", :content_type => "text/html", :locals => { :xss => params[:xss] }
  end

  def sql_with_case
    group_by_col =
      case params[:group_by]
      when 'brand'            then 'brand'
      when 'year'             then 'YEAR(date_utc)'
      when 'month'            then "CONCAT(YEAR(date_utc), '-', LPAD(MONTH(date_utc), 2, '0'))"
      when 'week'             then "CONCAT(YEAR(date_utc), '-', LPAD(WEEK(date_utc, 1), 2, '0'))"
      when 'day'              then "DATE(date_utc)"
      else raise ArgumentError, 'Invalid group by value'
      end

    query = "SELECT id, #{group_by_col} AS group_by_col, COUNT(*) FROM records"

    # No warnings
    rows = User.connection.select_rows(query)
  end

  def sql_with_another_case
    subset_clause = case script_subset
                    when :greasyfork
                      "AND `sensitive` = false"
                    when :sleazyfork
                      "AND `sensitive` = true"
                    else
                      ""
                    end
    sql =<<-EOF
  SELECT
    text, SUM(daily_installs) install_count, COUNT(s.id) script_count
  FROM script_applies_tos
  JOIN scripts s ON script_id = s.id
  WHERE
    domain
    AND script_type_id = 1
    AND script_delete_type_id IS NULL
    AND !tld_extra
    #{subset_clause}
  GROUP BY text
  ORDER BY text
    EOF

    # No warnings
    by_sites = User.connection.select_rows(sql)
  end

  def render_with_case
    # No warnings
    case params[:switch_case_on_this]
    when "one"
      render partial: params[:switch_case_on_this], locals: { x: 1 }
    when "two"
      render partial: params[:switch_case_on_this], locals: { x: 2 }
    end
  end

  def no_html
    @x = params[:x].html_safe
  end

  def guard_with_return
    goto = params[:goto]
    event = params[:event]
    return redirect_to user_path unless %w[comment subscribe].include?(goto)

    redirect_to send("#{goto}_event_path", event) # should not warn
  end

  def render_cookies
    render inline: request.cookies["value"]
  end

  def dangerous_permits
    params.permit(:admin)
    params.permit(:role_id)
  end

  def redirect_to_path
    session = User.find_by_token params[:session]

    if session
      # proceed with extracting user context from session and more and redirect to the last path the user was shown to
      login(session.user)
      redirect_to session.user.current_path
    else
      redirect_to expired_or_invalid_session_path
    end
  end

  def render_safely
    slug = params[:slug].to_s
    render slug if template_exists?(slug, 'pages')
  end
end

IDENTIFIER_NAMESPACE = 'apis'
