class Product < ActiveRecord::Base
  def test_find_order
    #Should warn, no escaping done for :order
    Product.find(:all, :order => params[:order])
    Product.find(:all, :conditions => 'admin = 1', :order => "name #{params[:order]}")
  end

  def test_find_group
    #Should warn, no escaping done for :group
    Product.find(:all, :conditions => 'admin = 1', :group => params[:group])
    Product.find(:all, :conditions => 'admin = 1', :group => "something, #{params[:group]}")
  end

  def test_find_having
    #Should warn
    Product.find(:first, :conditions => 'admin = 1', :having => "x = #{params[:having]}")

    #Should not warn, hash values are escaped
    Product.find(:first, :conditions => 'admin = 1', :having => { :x => params[:having]})

    #Should not warn, properly interpolated
    Product.find(:first, :conditions => ['name = ?', params[:name]], :having => [ 'x = ?', params[:having]])

    #Should warn, not quite properly interpolated
    Product.find(:first, :conditions => ['name = ?', params[:name]], :having => [ "admin = ? and x = #{params[:having]}", cookies[:admin]])
    Product.find(:first, :conditions => ['name = ?', params[:name]], :having => [ "admin = ? and x = '" + params[:having] + "'", cookies[:admin]])
  end

  def test_find_joins
    #Should not warn, string values are not going to have injection
    Product.find(:first, :conditions => 'admin = 1', :joins => "LEFT JOIN comments ON comments.post_id = id")

    #Should warn
    Product.find(:first, :conditions => 'admin = 1', :joins => "LEFT JOIN comments ON comments.#{params[:join]} = id")

    #Should not warn
    Product.find(:first, :conditions => 'admin = 1', :joins => [:x, :y])

    #Should warn
    Product.find(:first, :conditions => 'admin = 1', :joins => ["LEFT JOIN comments ON comments.#{params[:join]} = id", :x, :y])
  end

  def test_find_select
    #Should not warn, string values are not going to have injection
    Product.find(:last, :conditions => 'admin = 1', :select => "name")

    #Should warn
    Product.find(:last, :conditions => 'admin = 1', :select => params[:column])
    Product.find(:last, :conditions => 'admin = 1', :select => "name, #{params[:column]}")
    Product.find(:last, :conditions => 'admin = 1', :select => "name, " + params[:column])
  end

  def test_find_from
    #Should not warn, string values are not going to have injection
    Product.find(:last, :conditions => 'admin = 1', :from => "users")

    #Should warn
    Product.find(:last, :conditions => 'admin = 1', :from => params[:table])
    Product.find(:last, :conditions => 'admin = 1', :from => "#{params[:table]}")
  end

  def test_find_lock
    #Should not warn
    Product.find(:last, :conditions => 'admin = 1', :lock => true)

    #Should warn
    Product.find(:last, :conditions => 'admin = 1', :lock => params[:lock])
    Product.find(:last, :conditions => 'admin = 1', :lock => "LOCK #{params[:lock]}")
  end

  def test_where
    #Should not warn
    Product.where("admin = 1")
    Product.where("admin = ?", params[:admin])
    Product.where(["admin = ?", params[:admin]])
    Product.where(["admin = :admin", { :admin => params[:admin] }])
    Product.where(:admin => params[:admin])

    #Should warn
    Product.where("admin = '#{params[:admin]}'").first
    Product.where(["admin = ? AND user_name = #{@name}", params[:admin]])
  end

  TOTALLY_SAFE = "some safe string"

  def test_constant_interpolation
    #Should not warn
    Product.first("blah = #{TOTALLY_SAFE}")
  end

  def test_local_interpolation
    #Should warn, medium confidence
    Product.first("blah = #{local_var}")
  end

  def test_conditional_args_in_sql
    #Should warn
    Product.last("blah = '#{something ? params[:blah] : TOTALLY_SAFE}'")

    #Should not warn
    Product.last("blah = '#{params[:blah] ? 1 : 0}'")
  end

  def test_params_in_args
    #Should warn
    Product.last("blah = '#{something(params[:blah])}'")
  end

  def test_params_to_i
    #Should not warn
    Product.last("blah = '#{params[:id].to_i}'")
  end

  def test_more_if_statements
    if some_condition
      x = params[:x]
    else
      x = "BLAH"
    end

    y = if some_other_condition
      params[:x]
      "blah"
    else
      params[:y]
      "blah"
    end

    #Should warn
    Product.last("blah = '#{x}'")

    #Should not warn
    Product.last("blah = '#{y}'")
    Product.where("blah = 1").group(y)
  end

  def test_calculations
    #Should warn
    Product.calculate(:count, :all, :conditions => "blah = '#{params[:blah]}'")
    Product.minimum(:price, :conditions => "blah = #{params[:blach]}")
    Product.maximum(:price, :group => params[:columns])
    Product.average(:price, :conditions => ["blah = #{params[:columns]} and x = ?", x])
    Product.sum(params[:columns])
  end

  def test_select
    #Should not warn
    Product.select([:price, :sku])

    #Should warn
    Product.select params[:columns]
  end

  def test_conditional_in_options
    x = params[:x] == y ? "created_at ASC" : "created_at DESC"
    z = params[:y] == y ? "safe" : "totally safe"

    #Should not warn
    Product.all(:order => x, :having => z, :select => z, :from => z,
                :group => z)
  end

  def test_or_interpolation
    #Should not warn
    Product.where("blah = #{1 or 2}")
  end

  def test_params_to_f
    #Should not warn
    Product.last("blah = '#{params[:id].to_f}'")
  end

  def test_interpolation_in_first_arg
    Product.where("x = #{params[:x]} AND y = ?", y)
  end

  def test_to_sql_interpolation
    #Should not warn
    prices = Produt.select(:price).where("created_at < :time").to_sql

    where("price IN (#{prices}) OR whatever", :price => some_price)
  end
end
