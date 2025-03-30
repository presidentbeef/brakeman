require_relative '../test'

class Rails7Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||=
      Date.stub :today, Date.parse('2023-02-10') do
        BrakemanTester.run_scan "rails7", "Rails 7", :run_all_checks => true, gemfile: "MyGemfile"
      end
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :warning => 26
    }
  end

  def test_ruby_2_7_eol
    assert_warning check_name: "EOLRuby",
      type: :warning,
      warning_code: 123,
      fingerprint: "92f8b4d79a8f4abeffed8ce6683ca85c4c42df26c7e5ec4378fafa7b728044ce",
      warning_type: "Unmaintained Dependency",
      line: 235,
      message: /^Support\ for\ Ruby\ 2\.7\.0\ ends\ on\ 2023\-03\-3/,
      confidence: 2,
      relative_path: "MyGemfile.lock",
      code: nil,
      user_input: nil
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
      warning_code: 128,
      fingerprint: "74dd38e229f0343ce80891b7530c4ecf3446c2f214917f70a1044006c885a6b0",
      warning_type: "Weak Cryptography",
      line: 22,
      message: /^RSA\ key\ with\ size\ `1024`\ is\ considered\ w/,
      confidence: 1,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))),
      user_input: s(:lit, 1024)
  end

  def test_weak_cryptography_4
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "cc38689724cb70423c57d575290423054f0c998a7b897b2985e96da96f51e77e",
      warning_type: "Weak Cryptography",
      line: 4,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(default\ if\ no/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :public_encrypt, s(:call, s(:call, nil, :payload), :to_json)),
      user_input: nil
  end

  def test_weak_cryptography_5
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "53df5254e251a0ab8f6159df3dbdb1a77ff92c96589a213adb9847c2f255a479",
      warning_type: "Weak Cryptography",
      line: 5,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(default\ if\ no/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :private_decrypt, s(:call, s(:const, :Base64), :decode64, s(:call, s(:const, :Base64), :encode64, s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :public_encrypt, s(:call, s(:call, nil, :payload), :to_json))))),
      user_input: nil
  end

  def test_weak_cryptography_6
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

  def test_weak_cryptography_7
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "bf3a313e24667f5839385b4ad0e90bc51a4f6bf8b489dab152c03242641ebad9",
      warning_type: "Weak Cryptography",
      line: 11,
      message: /^No\ padding\ mode\ used\ for\ RSA\ key\.\ A\ safe/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :private_encrypt, s(:call, nil, :data), s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :NO_PADDING)),
      user_input: s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :NO_PADDING)
  end

  def test_weak_cryptography_8
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "7692aefd6fc53891734025f079ac062bf5b4ca69d1447f53de8f7e0cd389ae19",
      warning_type: "Weak Cryptography",
      line: 12,
      message: /^Use\ of\ padding\ mode\ SSLV23\ for\ RSA\ key,\ /,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :new, s(:str, "grab the public 4096 bit key")), :private_encrypt, s(:call, nil, :data), s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :SSLV23_PADDING)),
      user_input: s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :SSLV23_PADDING)
  end

  def test_weak_cryptography_9
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "386909718cfc8427e4509912c7c22b0f99ce2e052bb505ccfe6b400e3fd21632",
      warning_type: "Weak Cryptography",
      line: 23,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(default\ if\ no/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))), :encrypt, s(:str, "data"), s(:hash, s(:str, "rsa_padding_mode"), s(:str, "pkcs1"))),
      user_input: s(:str, "pkcs1")
  end

  def test_weak_cryptography_10
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "3a3f24bb81d480515081aee1ebdf76d34c79b6e0c3c1946513158164512f9130",
      warning_type: "Weak Cryptography",
      line: 25,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(default\ if\ no/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))), :sign, s(:str, "SHA256"), s(:str, "data"), s(:hash, s(:lit, :rsa_padding_mode), s(:str, "PKCS1"))),
      user_input: s(:str, "pkcs1")
  end

  def test_weak_cryptography_11
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "0b6b1f354c2380be841134447c315a24c2919d61fbb4de51af3dafc66e2144c3",
      warning_type: "Weak Cryptography",
      line: 26,
      message: /^No\ padding\ mode\ used\ for\ RSA\ key\.\ A\ safe/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))), :verify, s(:str, "SHA256"), s(:str, "data"), s(:hash, s(:lit, :rsa_padding_mode), s(:str, "none"))),
      user_input: s(:str, "none")
  end

  def test_weak_cryptography_12
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "cf7d2b90d591ca7a442992caf39b858c4e599c9f2f4d82fa09e40b250f9c8e78",
      warning_type: "Weak Cryptography",
      line: 27,
      message: /^No\ padding\ mode\ used\ for\ RSA\ key\.\ A\ safe/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))), :sign_raw, s(:nil), s(:str, "data"), s(:hash, s(:lit, :rsa_padding_mode), s(:str, "none"))),
      user_input: s(:str, "none")
  end

  def test_weak_cryptography_13
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "6a9835fa708e6f92797c4c1164b32446fe028672ba7ad652d3a474072658e271",
      warning_type: "Weak Cryptography",
      line: 28,
      message: /^No\ padding\ mode\ used\ for\ RSA\ key\.\ A\ safe/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))), :verify_raw, s(:nil), s(:str, "data"), s(:hash, s(:lit, :rsa_padding_mode), s(:str, "none"))),
      user_input: s(:str, "none")
  end

  def test_weak_cryptography_14
    assert_warning check_name: "WeakRSAKey",
      type: :warning,
      warning_code: 126,
      fingerprint: "a7c85f295d9ea5356afbdf9165eb5bcfb892646f5f9a5a73b514a835456b419b",
      warning_type: "Weak Cryptography",
      line: 29,
      message: /^Use\ of\ padding\ mode\ PKCS1\ \(default\ if\ no/,
      confidence: 0,
      relative_path: "lib/some_lib.rb",
      code: s(:call, s(:call, s(:colon2, s(:const, :OpenSSL), :PKey), :generate_key, s(:str, "rsa"), s(:hash, s(:lit, :rsa_keygen_bits), s(:lit, 1024))), :encrypt, s(:str, "data")),
      user_input: nil
  end

  def test_presence_in_with_render_path_false_positive
    assert_no_warning check_name: "Render",
      type: :warning,
      warning_code: 15,
      fingerprint: "32762c066cbafafce28947fb91f24cd547c52f184084fb4dc05ac9ff81def638",
      warning_type: "Dynamic Render Path",
      line: 9,
      message: /^Render\ path\ contains\ parameter\ value/,
      confidence: 1,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:render, :action, s(:dstr, "admin2/fields/", s(:evstr, s(:or, s(:call, s(:call, s(:params), :[], s(:lit, :field)), :presence_in, s(:array, s(:str, "foo"))), s(:call, nil, :raise, s(:colon2, s(:const, :ActionController), :BadRequest))))), s(:hash)),
      user_input: s(:call, s(:call, s(:params), :[], s(:lit, :field)), :presence_in, s(:array, s(:str, "foo")))
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

  def test_cross_site_scripting_content_tag
    assert_no_warning check_name: "ContentTag",
      type: :template,
      warning_code: 53,
      warning_type: "Cross-Site Scripting",
      line: 2,
      message: /^Unescaped\ parameter\ value\ in\ `content_ta/,
      confidence: 0,
      relative_path: "app/views/users/index.html.erb",
      code: s(:call, nil, :content_tag, s(:lit, :b), s(:call, nil, :cool_content), s(:hash, s(:call, s(:call, nil, :params), :[], s(:lit, :stuff)), s(:call, s(:call, nil, :params), :[], s(:lit, :things)))),
      user_input: s(:call, s(:call, nil, :params), :[], s(:lit, :stuff))
  end

  def test_redirect_1
    assert_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "0e6b36e8598a024ef8832d7af1a5b0089f6b00f96c17e2ccdb87aca012e6f76f",
      warning_type: "Redirect",
      line: 13,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_to, s(:or, s(:call, s(:params), :[], s(:lit, :redirect_url)), s(:str, "/"))),
      user_input: s(:call, s(:params), :[], s(:lit, :redirect_url))
  end

  def test_redirect_2
    assert_no_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "f6ddaf32c99db9912fb0a78d79f81701a893e6b283ddad5709393b09c6c693bc",
      warning_type: "Redirect",
      line: 17,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 2,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_to, s(:or, s(:call, nil, :url_from, s(:call, s(:params), :[], s(:lit, :redirect_url))), s(:str, "/"))),
      user_input: s(:call, s(:params), :[], s(:lit, :redirect_url))
  end

  def test_redirect_disallow_other_host
    assert_no_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "cef6913575a0db9d43acdb945fd8d7f5b1ea3e0a19c457d9c85bf673e67a4a85",
      warning_type: "Redirect",
      line: 25,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_to, s(:call, s(:params), :[], s(:lit, :x)), s(:hash, s(:lit, :allow_other_host), s(:false))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_redirect_allow_other_host
    assert_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "a1fdd251c91d225a187a41b9b4acf88412d86a834b597fa58a17d208681b8a00",
      warning_type: "Redirect",
      line: 21,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 2,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_to, s(:call, s(:params), :[], s(:lit, :x)), s(:hash, s(:lit, :allow_other_host), s(:true))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_redirect_back
    assert_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "81ee1b43b1a16a2e143669adb3259407bb462f1963d339717662d9271a154909",
      warning_type: "Redirect",
      line: 29,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_back, s(:hash, s(:lit, :fallback_location), s(:call, s(:params), :[], s(:lit, :x)))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_redirect_back_or_to
    assert_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "e5aed5eb26b588f3cb6f9f7d34c63ceffcb574348c4fd3c8464e11cab16ed3e3",
      warning_type: "Redirect",
      line: 33,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_back_or_to, s(:call, s(:params), :[], s(:lit, :x))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_missing_authorization_ransack
    assert_warning check_name: "Ransack",
      type: :warning,
      warning_code: 129,
      fingerprint: "ae28bfeb8423952ffae97149292175b2d10c36c4904ee198ab7b2eda4e05c3e0",
      warning_type: "Missing Authorization",
      line: 41,
      message: /^Unrestricted\ search\ using\ `ransack`\ libr/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, s(:const, :User), :ransack, s(:call, s(:params), :[], s(:lit, :q))),
      user_input: s(:call, s(:params), :[], s(:lit, :q))
  end

  def test_missing_authorization_ransack_admin
    assert_warning check_name: "Ransack",
      type: :warning,
      warning_code: 129,
      fingerprint: "cb03f7424bc739b26e3789e2d9bb6893b4f2f517dbe10d4d3f3f19b4cf845459",
      warning_type: "Missing Authorization",
      line: 4,
      message: /^Unrestricted\ search\ using\ `ransack`\ libr/,
      confidence: 1,
      relative_path: "app/controllers/admin_controller.rb",
      code: s(:call, s(:const, :User), :ransack, s(:call, s(:params), :[], s(:lit, :q))),
      user_input: s(:call, s(:params), :[], s(:lit, :q))
  end

  def test_missing_authorization_ransack_2
    assert_no_warning check_name: "Ransack",
      type: :warning,
      warning_code: 129,
      warning_type: "Missing Authorization",
      line: 46,
      message: /^Unrestricted\ search\ using\ `ransack`\ libr/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb"
  end

  def test_missing_authorization_ransack_low
    assert_warning check_name: "Ransack",
      type: :warning,
      warning_code: 129,
      fingerprint: "50e236d8fbc9db0f67e0011941b92b08d0ece176ce4b8caea89d372f007a4873",
      warning_type: "Missing Authorization",
      line: 49,
      message: /^Unrestricted\ search\ using\ `ransack`\ libr/,
      confidence: 2,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, s(:call, s(:call, nil, :some_book), :things), :ransack, s(:call, s(:params), :[], s(:lit, :q))),
      user_input: s(:call, s(:params), :[], s(:lit, :q))
  end
end
