class User < ActiveRecord::Base
  #Should not raise a warning
  def unused_sql
    if true
      @x = z
    elsif somethingelse
      @x = "name like '%#{params[:name]}%'"
    else
      @x ="foo"
    end

    User.where(@x)

    if true
      x = z
    elsif false
      x = "name like '%#{params[:name]}%'"
    else
      x ="foo"
    end

    User.where(x)
  end

  def sql_in_if_branches
    if condition
      x = z
    elsif other_condition
      x = "name like '%#{params[:name]}%'"
    end

    User.where(x)
  end

  def safe_sql
    User.where "something = ?", "#{params[:awesome]}"
  end

  def sanitized_profile
    sanitize self.profile.to_s
  end

  serialize :something
end
