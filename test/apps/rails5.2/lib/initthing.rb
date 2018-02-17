class InitThing
  def initialize
    @blah = "some cool stuff"
  end

  def use_it
    `#{@blah}`
  end
end
