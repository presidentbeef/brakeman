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
end
