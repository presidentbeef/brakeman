class UsersController < ApplicationController
  def index
    index_params = params.permit(:name, friend_names: []).to_hash
    User.where(index_params).qualify.all
  end

  def show
    show_params = params.permit(:id, :name).to_hash.symbolize_keys
    User.where(show_params).qualify.all
  end

  ALLOWED_FOOS = [:bar, :baz].freeze
  def delete(foo)
    unless ALLOWED_FOOS.include? foo
      raise ArgumentError, "Unexpected foo: #{foo}"
    end

    Person.where("#{foo} >= 1")
  end

  def safe_one(foo)
    return if !ALLOWED_FOOS.include?(foo)

    Person.where("#{foo} >= 1")
  end

  def better_user_input_reporting
    table = Something.selection.select { |x| some_condition? x }.map { |x| "#{User.table_name}.#{x}" } 

    # Should report SQLi, but not about User.table_name specifically
    User.find_by_sql("SELECT #{"#{table}.name"} where name = #{params[:name]}")
  end

  def splat_args 
    Person.where(*params[:foo]).qualify.all
  end

  def splat_kwargs
    User.where(**params[:foo]).qualify.all
  end

  def one
    @user = User.find(params[:id])
  end

  def two
    @user = User.find(params[:id])
  end

  def some_api
    Oj.load(params[:json]) # Unsafe by default
    Oj.load(params[:json], mode: :object) # Unsafe, regardless of default
    Oj.object_load(params[:json], mode: :strict) # Always unsafe, regardless of mode
    Oj.load(params[:json], mode: :strict) # Safe
  end

  def not_not
    si = ManualCSVImport.new(header_row: !!params[:header_row], archive: !!params[:archive])
    @errors = [si.results[:invalid_info], si.results[:ignored_info]].flatten
  end

  def test_empty_partial_name
  end
end
