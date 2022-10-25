require_relative '../test'

class Rails7Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails7", "Rails 7", :run_all_checks => true
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :warning => 10
    }
  end

  def test_missing_encryption_1
    assert_warning :type => :warning,
      :warning_code => 109,
      :fingerprint => "6a26086cd2400fbbfb831b2f8d7291e320bcc2b36984d2abc359e41b3b63212b",
      :warning_type => "Missing Encryption",
      :line => 1,
      :message => /^The\ application\ does\ not\ force\ use\ of\ HT/,
      :confidence => 0,
      :relative_path => "config/environments/production.rb",
      :code => nil,
      :user_input => nil
  end

  def test_path_traversal_1
    assert_warning check_name: "Pathname",
      type: :warning,
      warning_code: 125,
      fingerprint: "1797967f82af2ce9213b465cd77c98bd08b36b6ed748a50e2d72a5e1c5c83461",
      warning_type: "Path Traversal",
      line: 30,
      message: /^Absolute\ paths\ in\ `Pathname\#join`\ cause\ /,
      confidence: 0,
      relative_path: "app/controllers/application_controller.rb",
      code: s(:call, s(:call, s(:const, :Rails), :root), :join, s(:str, "a"), s(:str, "b"), s(:dstr, "", s(:evstr, s(:call, s(:params), :[], s(:lit, :c))))),
      user_input: s(:call, s(:params), :[], s(:lit, :c))
  end

  def test_path_traversal_2
    assert_warning check_name: "Pathname",
      type: :warning,
      warning_code: 125,
      fingerprint: "b5ff15be27c93ea4b88c3affe638affb2a255d1b6ac6c8e90ee1536f6001e73d",
      warning_type: "Path Traversal",
      line: 27,
      message: /^Absolute\ paths\ in\ `Pathname\#join`\ cause\ /,
      confidence: 0,
      relative_path: "app/controllers/application_controller.rb",
      code: s(:call, s(:call, s(:const, :Pathname), :new, s(:str, "a")), :join, s(:call, s(:params), :[], s(:lit, :x)), s(:str, "z")),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_redirect_to_last
    assert_no_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "86a37d9ade23cec9901c80ad7c6fa7581d6257783dd56f2cddfd6adda4efc95a",
      warning_type: "Redirect",
      line: 3,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_to, s(:call, s(:const, :User), :last!)),
      user_input: s(:call, s(:const, :User), :last!)
  end

  def test_weak_cryptography_1
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 128,
      fingerprint: "4c4db18f4142dac0b271136f6bcf8bee08f0585bd9640676a12cdb80b1d7f02d",
      warning_type: "Weak Cryptography",
      line: 16,
      message: /^RSA\ key\ with\ size\ `512`\ is\ considered\ ve/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :generate, s(:lit, 512)),
      user_input: s(:lit, 512)
  end

  def test_weak_cryptography_2
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 128,
      fingerprint: "0f23edef18a0d092581daff053a88b523a56f50c03367907c0167af50d01dec2",
      warning_type: "Weak Cryptography",
      line: 17,
      message: /^RSA\ key\ with\ size\ `1024`\ is\ considered\ w/,
      confidence: 1,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:lit, 1024)),
      user_input: s(:lit, 1024)
  end

  def test_weak_cryptography_3
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "cc38689724cb70423c57d575290423054f0c998a7b897b2985e96da96f51e77e",
      warning_type: "Weak Cryptography",
      line: 4,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(defa/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :public_encrypt, s(:call, s(:call, nil, :payload), :to_json)),
      user_input: nil
  end

  def test_weak_cryptography_4
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "53df5254e251a0ab8f6159df3dbdb1a77ff92c96589a213adb9847c2f255a479",
      warning_type: "Weak Cryptography",
      line: 5,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(defa/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :private_decrypt, s(:call, s(:const, :Base64), :decode64, s(:call, s(:const, :Base64), :encode64, s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :public_encrypt, s(:call, s(:call, nil, :payload), :to_json))))),
      user_input: nil
  end

  def test_weak_cryptography_5
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "c8a3c3c409f64eae926ce9b60d85d243f86bc8448d1ba7b5880f192eb54089d7",
      warning_type: "Weak Cryptography",
      line: 10,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(default\ if\ no/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :public_decrypt, s(:call, nil, :data), s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :PKCS1_PADDING)),
      user_input: s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :PKCS1_PADDING)
  end

    def test_weak_cryptography_6
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 127,
      fingerprint: "47462db72333e2287d0b3670295f875700e85f516b4276ec5acf2f99f3809b04",
      warning_type: "Weak Cryptography",
      line: 11,
      message: /^No\ padding\ mode\ used\ for\ RSA\ key\.\ A\ safe/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :private_encrypt, s(:call, nil, :data), s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :NO_PADDING)),
      user_input: s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :NO_PADDING)
  end

  def test_cross_site_scripting_CVE_2022_32209_allowed_tags_initializer
    assert_warning check_name: "SanitizeConfigCve",
      type: :warning,
      warning_code: 124,
      fingerprint: "c2cc471a99036432e03d83e893fe748c2b1d5c40a39e776475faf088717af97d",
      warning_type: "Cross-Site Scripting",
      line: 1,
      message: /^rails\-html\-sanitizer\ 1\.4\.2\ is\ vulnerable/,
      confidence: 0,
      relative_path: "config/initializers/sanitizers.rb",
      code: s(:attrasgn, s(:colon2, s(:colon2, s(:const, :Rails), :Html), :SafeListSanitizer), :allowed_tags=, s(:array, s(:str, "select"), s(:str, "a"), s(:str, "style"))),
      user_input: nil
  end
end
