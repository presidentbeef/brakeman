class MyLib
  def test_negative_array_index
    #This should not cause an error, but it used to
    [][-1]
    [-1][-1]
  end
end
