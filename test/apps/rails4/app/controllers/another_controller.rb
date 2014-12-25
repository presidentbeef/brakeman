class AnotherController < ApplicationController
  def overflow
    @test = @test.where.all
  end

  before_filter do
    eval params[:x]
  end

  skip_before_action :set_bad_thing, :except => [:also_use_bad_thing]

  def use_bad_thing
    # This should not warn, because the filter is skipped!
    User.where(@bad_thing)
  end

  def also_use_bad_thing
    `#{@bad_thing}`
  end
end
