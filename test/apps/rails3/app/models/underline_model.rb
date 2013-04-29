class Underline_Model
  def inject!(b)
    User.where("a < #{b}")
  end
end
