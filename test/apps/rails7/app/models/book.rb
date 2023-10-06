class Book < Thing
  def self.ransackable_attributes(auth_object = nil)
    [:author, :title]
  end
end
