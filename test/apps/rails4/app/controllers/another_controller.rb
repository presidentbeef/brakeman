class AnotherController < ApplicationController
  def overflow
    @test = @test.where.all
  end
end
