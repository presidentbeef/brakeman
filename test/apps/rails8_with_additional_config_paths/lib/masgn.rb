def test_masgn_recursion
  r = lambda {
    x, q = r
  }

  y, z = r
end
