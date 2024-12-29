require_relative '../test'

class Rails3Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails3", "Rails 3", :rails3 => true,
      :config_file => File.join(TEST_PATH, "apps", "rails3", "config", "brakeman.yml")
  end

  def expected
    @expected ||= {
      :controller => 1,
      :model => 9,
      :template => 41,
      :generic => 79
    }

    if RUBY_PLATFORM == 'java'
      @expected[:generic] += 1
    end

    @expected
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end

  def test_config_sanity
    assert_equal 'utf-8', report[:config].rails[:encoding].value
  end

  def test_eval_params
    assert_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "4efdd73fb759135f5980b5da1d9804aa4eb5c7475eabfd0f0cf41299d1d7ec42",
      :warning_type => "Dangerous Eval",
      :line => 40,
      :message => /^Parameter\ value\ evaluated\ as\ code/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_class_eval_false_positive
    assert_no_warning :type => :warning,
      :warning_type => "Dangerous Eval",
      :line => 13,
      :message => /^User input in eval/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_command_injection_params_interpolation
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "d68453d17bca16814e8eaffdce5b1dcf3e87aeeca2d94f3dcf78e309cb1b29c6",
      :warning_type => "Command Injection",
      :line => 34,
      :message => /^Possible command injection near line 34:/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_command_injection_system_params
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 36,
      :message => /^Possible command injection near line 36:/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_command_injection_non_user_input_backticks
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 48,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :file => /other_controller\.rb/
  end

  def test_command_injection_non_user_input_system
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 49,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :file => /other_controller\.rb/
  end

  def test_command_injection_capture2
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "a9e14a8381114ec58551a94c281c36782ec9d6d91d93c346e6e4f7a6f32e9c25",
      :warning_type => "Command Injection",
      :line => 146,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_capture2e
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "99283cfdb2799fc278d5e474d11dc952ead57861e29470cf5ac16629a5b07fb2",
      :warning_type => "Command Injection",
      :line => 147,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_capture3
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "1c7506f2977852c07f8e41dcdad205794048b258b557e7d322acf86fab0a6877",
      :warning_type => "Command Injection",
      :line => 148,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_pipeline
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "a72b42173ccbc912f022e73a37afc57b8099a529a9f28ebd9e3e771ad384b81c",
      :warning_type => "Command Injection",
      :line => 149,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_pipeline_r
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "f28aa6e2e73662dd58169db727fc30099da36a9e0d1817375bb257faed376e52",
      :warning_type => "Command Injection",
      :line => 150,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_pipeline_rw
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "02485597e19623e805dfa48a797f6f453d854f87ea03e51330494bf671bf5f68",
      :warning_type => "Command Injection",
      :line => 151,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_pipeline_start
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "c38ddfa0340fcaaa2a626de722a7784a0448fce01b58601c9c159113d1ce6e5f",
      :warning_type => "Command Injection",
      :line => 152,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_pipeline_safe_ish
    assert_no_warning check_name: "Execute",
      type: :warning,
      warning_code: 14,
      fingerprint: "69631817be6f91b3e9115935a0b5e23b6cd642bdb44ac5edb83ce9bf5c207528",
      warning_type: "Command Injection",
      line: 162,
      message: /^Possible\ command\ injection/,
      confidence: 0,
      relative_path: "app/controllers/home_controller.rb",
      code: s(:call, s(:const, :Open3), :pipeline, s(:array, s(:str, "sort"), s(:call, s(:params), :[], s(:lit, :file)))),
      user_input: s(:call, s(:params), :[], s(:lit, :file))
  end

  def test_command_injection_pipeline_array_cmd
    assert_warning check_name: "Execute",
      type: :warning,
      warning_code: 14,
      fingerprint: "209d96d55ba1cdbce58da49efaea6c3da266411c9a4e3ba914b80969b0ebc4c8",
      warning_type: "Command Injection",
      line: 163,
      message: /^Possible\ command\ injection/,
      confidence: 0,
      relative_path: "app/controllers/home_controller.rb",
      code: s(:call, s(:const, :Open3), :pipeline_r, s(:array, s(:str, "ls"), s(:str, "*")), s(:dstr, "sort ", s(:evstr, s(:call, s(:params), :[], s(:lit, :order))))),
      user_input: s(:call, s(:params), :[], s(:lit, :order))
  end

  def test_command_injection_pipeline_two_array_commands
    assert_warning check_name: "Execute",
      type: :warning,
      warning_code: 14,
      fingerprint: "a64f8ffded9992faa6291a1448ea49b9121b29d00cc09d01f3608c57131f778a",
      warning_type: "Command Injection",
      line: 164,
      message: /^Possible\ command\ injection/,
      confidence: 0,
      relative_path: "app/controllers/home_controller.rb",
      code: s(:call, s(:const, :Open3), :pipeline_rw, s(:array, s(:str, "ls")), s(:array, s(:call, s(:params), :[], s(:lit, :cmd)))),
      user_input: s(:call, s(:params), :[], s(:lit, :cmd))
  end

  def test_command_injection_pipeline_bash_c
    assert_warning check_name: "Execute",
      type: :warning,
      warning_code: 14,
      fingerprint: "386d96b25b2ca16ff668be680ddf4669fe4f37e12f60506f67971d99ba2f4250",
      warning_type: "Command Injection",
      line: 165,
      message: /^Possible\ command\ injection/,
      confidence: 0,
      relative_path: "app/controllers/home_controller.rb",
      code: s(:call, s(:const, :Open3), :pipeline_start, s(:array, s(:str, "bash"), s(:str, "-c"), s(:call, s(:params), :[], s(:lit, :cmd)))),
      user_input: s(:call, s(:params), :[], s(:lit, :cmd))
  end

  def test_command_injection_spawn
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "73d4d3114ea536247c38a4e0d5bbcde047ea3f304d2e6a22b1693003d5135409",
      :warning_type => "Command Injection",
      :line => 153,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_posix_spawn
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "678ea7e0c73c91df335247b2470678dd23dfe66f049add9c783e3de4fb6e5046",
      :warning_type => "Command Injection",
      :line => 154,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_file_access_concatenation
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 24,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_load
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 67,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_yaml_load
    assert_no_warning :type => :warning,
      :warning_type => "File Access",
      :line => 106,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_yaml_parse_file
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 109,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 54,
      :message => /^Unprotected mass assignment near line 54/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_protected_mass_assignment
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 43,
      :message => /^Unprotected mass assignment near line 43: Product.new/,
      :confidence => 1,
      :file => /products_controller\.rb/
  end

  def test_protected_mass_assignment_update
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 62,
      :message => /^Unprotected mass assignment near line 62: Product.find/,
      :confidence => 1,
      :file => /products_controller\.rb/
  end

  def test_update_attribute_no_mass_assignment
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 26,
      :message => /^Unprotected mass assignment near line 26/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 45,
      :message => /^Possible unprotected redirect near line /,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_redirect_to_model_instance
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 63,
      :message => /^Possible unprotected redirect near line 63: redirect_to/,
      :confidence => 2,
      :file => /products_controller\.rb/
  end

  def test_redirect_only_path_in_wrong_argument
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 77,
      :message => /^Possible unprotected redirect near line 77: redirect_to\(params\[/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_redirect_url_for_not_only_path
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 83,
      :message => /^Possible unprotected redirect near line 83: redirect_to\(url_for/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_redirect_url_only_path
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 158,
      :message => /^Possible unprotected redirect near line 159: redirect_to\(params\[/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_render_path
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 63,
      :message => /^Render path contains parameter value near line 63: render/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_file_access_send_file
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 21,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_rails_cve_2012_2660
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2660/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_rails_cve_2012_2661
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2661/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_rails_cve_2012_2695
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2695/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-5664/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_find_by_sql
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 28,
      :message => /^Possible SQL injection near line 28: Use/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_unknown_variable
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 29,
      :message => /^Possible SQL injection near line 29: Use/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_params
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible SQL injection near line 30: Use/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_non_active_record_model
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "f804d0d9f3f0ecddf8cec14aa7bdc0020db864252cd2e7d7e3a7081c45363a7d",
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/other_controller.rb",
      :code => s(:call, s(:const, :Noticia), :where, s(:call, s(:params), :[], s(:lit, :bad_stuff))),
      :user_input => s(:call, s(:params), :[], s(:lit, :bad_stuff))
  end

  def test_csrf_protection
    assert_warning :type => :controller,
      :warning_code => 7,
      :fingerprint => "6f5239fb87c64764d0c209014deb5cf504c2c10ee424bd33590f0a4f22e01d8f",
      :warning_type => "Cross-Site Request Forgery",
      :line => 1,
      :message => /^`protect_from_forgery`\ should\ be\ called\ /,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb",
      :user_input => nil
  end

  def test_attribute_restriction
    assert_warning :type => :model,
      :warning_code => 19,
      :fingerprint => "91d73b1b9d6920156b920729c0146292eb9f10f4ba9515740442dbe82d4dee78",
      :warning_type => "Attribute Restriction",
      :line => 1,
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :relative_path => "app/models/account.rb"

    assert_warning :type => :model,
      :warning_code => 19,
      :fingerprint => "b325ae8a4570599cde146875ae86427506befae36a3b4a97ce2223930846fec5",
      :warning_type => "Attribute Restriction",
      :line => 1,
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :relative_path => "app/models/user.rb"
  end

  def test_attr_protected
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :message => /^`attr_protected` is bypassable in/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_format_validation
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 2,
      :message => /^Insufficient validation for `name` using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_format_validation_with_z
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 3,
      :message => /^Insufficient validation for `blah` using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_format_validation_with_a
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 4,
      :message => /^Insufficient validation for `something` using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_allowable_validation
    results = find :type => :model,
      :warning_type => "Format Validation",
      :line => 5,
      :message => /^Insufficient validation/,
      :confidence => 0,
      :file => /account\.rb/

    assert_equal 0, results.length, "Validation was allowable, should not raise warning"
  end

  def test_allowable_validation_with_Z
    results = find :type => :model,
      :warning_type => "Format Validation",
      :line => 6,
      :message => /^Insufficient validation/,
      :confidence => 0,
      :file => /account\.rb/

    assert_equal 0, results.length, "Validation was allowable, should not raise warning"
  end

  def test_xss_parameter_direct
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value near line 3: p/,
      :confidence => 0,
      :file => /index\.html\.erb/
  end

  def test_xss_parameter_variable
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 5,
      :message => /^Unescaped parameter value near line 5: p/,
      :confidence => 0,
      :file => /index\.html\.erb/
  end

  def test_xss_parameter_locals
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value near line 4: p/,
      :confidence => 0,
      :file => /test_locals\.html\.erb/
  end

  def test_xss_model_collection
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped model attribute near line 1: User.new.first_name/,
      :confidence => 0,
      :file => /_user\.html\.erb/
  end

  def test_xss_model
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_xss_model_known_bad
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped model attribute near line 6: a/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_model_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 8,
      :message => /^Unescaped model attribute in `link_to`/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_encoded_href_parameter_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 12,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_href_parameter_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 14,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/

    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 16,
      :message => /^Unsafe parameter value in `link_to` href/,
      :file => /test_params\.html\.erb/

    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 18,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_newlines_in_template
    # Brakeman previously handled multiple newlines between nested ruby
    # expressions incorrectly. This test verifies that multiple newlines between
    # ruby expressions does not lead to incorrect line numbers in warnings.
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 5,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 0,
      :file => /test_newlines\.html\.erb/

    # Brakeman previously handled multiple newlines between HTML markup and ruby
    # expressions incorrectly. This test verifies that multiple newlines between
    # HTML and ruby expressions does not lead to incorrect line numbers in
    # warnings.
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 12,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 0,
      :file => /test_newlines\.html\.erb/
  end

  def test_polymorphic_url_in_href
    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 10,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/

    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 12,
      :message => /^Unsafe parameter value in `link_to` href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/
  end

  def test_cross_site_scripting_alias_u_for_link_to_href
    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "395a4782d1e015e32c62aff7b3811533d91015935bc1b4258ad17b264dcdf6fe",
      :warning_type => "Cross-Site Scripting",
      :line => 14,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/home/test_model.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "test"), s(:call, s(:params), :[], s(:lit, :user_id))),
      :user_input => s(:call, s(:params), :[], s(:lit, :user_id))
  end

  def test_file_access_in_template
    assert_warning :type => :template,
      :warning_type => "File Access",
      :line => 3,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /test_file_access\.html\.erb/
  end

  def test_xss_cookie_direct
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/
  end

  def test_xss_filter
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_filter\.html\.erb/
  end

  def test_xss_iteration
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/
  end

  def test_xss_iteration2
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/
  end

  def test_unescaped_model
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
  end

  def test_xss_params
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_indirect_xss
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /test_params\.html\.erb/
  end

  def test_cross_site_scripting_alias_u
    assert_no_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "a1f78b7e1ff25f81054b5ed38d04457e76278ba38444cb65f93cd559f9545bd9",
      :warning_type => "Cross-Site Scripting",
      :line => 22,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/home/test_params.html.erb",
      :code => s(:call, s(:params), :[], s(:lit, :w00t)),
      :user_input => nil
  end

  def test_sql_injection_in_template
    #SQL injection in controllers should not warn again in views
    assert_no_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
  end

  def test_sql_injection_via_if
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 32,
      :message => /^Possible SQL injection near line 32: User.where/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_sqli_in_unusual_model_name
    assert_warning :type => :warning,
      :warning_code => 0,
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :file => /underline_model\.rb/
  end

  def test_sql_injection_delete_all
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "4045f9ab95a70f3674f6e1ff7c1f0ac7bdd9ab39bf111f1d0c0b7a386643fbff",
      :warning_type => "SQL Injection",
      :line => 57,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :name))
  end

  def test_sql_injection_destroy_all
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "7bbc1feebc89050e053bd3a24b9b00fe5d1879650368e82ee22b3cbc371a9ec3",
      :warning_type => "SQL Injection",
      :line => 58,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => s(:call, s(:call, s(:const, :User), :current), :humanity)
  end

  def test_sql_injection_to_s_value
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "0cf32bcc2320f59c97d4f5e051a764ee4fe7af987149ff118bce9900ff7a2faa",
      :warning_type => "SQL Injection",
      :line => 64,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => s(:call, nil, :product_action_type_key)

    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "6066950e19a729359e867b882323ef75334791bdceac75a16f586fc53f3318a0",
      :warning_type => "SQL Injection",
      :line => 68,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => s(:lvar, :status)

    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "c36f33e3b004e081622f1829be288ebdad673a7bf04922eb1d2b9a3d701362a1"
  end

  def test_escape_once
    results = find :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /index\.html\.erb/

    assert_equal 0, results.length, "escape_once is a safe method"
  end

  def test_indirect_cookie
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 5,
      :message => /^Unescaped cookie value/,
      :confidence => 2,
      :file => /test_cookie\.html\.erb/
  end

  #Check for params that look like params[:x][:y]
  def test_params_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 10,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  #Check for cookies that look like cookies[:blah][:blah]
  def test_cookies_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 7,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/
  end

  def test_default_routes
    assert_warning :warning_type => "Default Routes",
      :line => 101,
      :message => /All public methods in controllers are available as actions/,
      :file => /routes\.rb/
  end

  def test_user_input_in_mass_assignment
    assert_no_warning :warning_type => "Mass Assignment",
      :line => 58,
      :message => /^Unprotected mass assignment/,
      :confidence => 2,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_in_chained_call
    assert_warning :warning_type => "Mass Assignment",
      :line => 9,
      :message => /^Unprotected mass assignment near line 9: Account.new/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_mass_assign_with_strong_params
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 53,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_mass_assignment_first_or_create
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 114,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_first_or_create!
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 115,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 2,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_first_or_initialize!
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 116,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_update
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 118,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_assign_attributes
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 119,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_with_slice
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 141,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_with_only
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 142,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_translate_bug
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :message => /^Rails\ 3\.0\.3\ has\ a\ vulnerability\ in\ the\ t/, 
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_model_build
    assert_warning :warning_type => "Mass Assignment",
      :line => 73,
      :message => /^Unprotected mass assignment near line 73: User.new.something.something/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_string_buffer_manipulation_bug
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :message => /^Rails 3\.\d\.\d has a vulnerability in `SafeBuffer`. Upgrade to Rails 3.0.12/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_rails3_render_partial
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 15,
      :message => /^Unescaped model attribute near line 15: Product/,
      :confidence => 0,
      :file => /_form\.html\.erb/
  end

  def test_xss_content_tag_raw_content
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 8,
      :message => /^Unescaped\ parameter\ value\ in\ `content_tag`/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_attribute_name
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 14,
      :message => /^Unescaped\ cookie\ value\ in\ `content_tag`/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_attribute_name_even_with_escape
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 20,
      :message => /^Unescaped\ model\ attribute\ in\ `content_tag`/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_unescaped_attribute
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 26,
      :message => /^Unescaped\ model\ attribute\ in\ `content_tag`/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_in_tag_name
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 32,
      :message => /^Unescaped\ parameter\ value\ in\ `content_tag`/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_cross_site_scripting_u_alias_for_content_tag
    assert_no_warning :type => :template,
      :warning_code => 53,
      :fingerprint => "2bfdd98472f9f235b3ea683a4d911749b0c1b7ae169be697657304724d780595",
      :warning_type => "Cross-Site Scripting",
      :line => 38,
      :message => /^Unescaped\ parameter\ value\ in\ `content_tag`/,
      :confidence => 0,
      :relative_path => "app/views/home/test_content_tag.html.erb",
      :code => s(:call, nil, :content_tag, s(:lit, :span), s(:str, "test"), s(:hash, s(:call, s(:params), :[], s(:lit, :class)), s(:str, "display:none"))),
      :user_input => s(:call, s(:params), :[], s(:lit, :class))
  end

  def test_cross_site_scripting_prepend_filter
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /use_filter12345\.html\.erb/
  end

  def test_cross_site_scripting_append_filter
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /use_filter12345\.html\.erb/
  end

  def test_cross_site_scripting_prepend_filter_overwrite
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 5,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /use_filter12345\.html\.erb/
  end

  def test_cross_site_scripting_prepend_filter_overwrite_2
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 8,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /use_filter12345\.html\.erb/
  end

  def test_cross_site_scripting_CVE_2016_6316
    assert_warning :type => :template,
      :warning_code => 53,
      :fingerprint => "0787a388cdb27d68d2e1591d02a3c84f0bc6938ede52139471082386798f7327",
      :warning_type => "Cross-Site Scripting",
      :line => 11,
      :message => /^Unescaped\ parameter\ value\ in\ `content_tag`/,
      :confidence => 0,
      :relative_path => "app/views/home/test_content_tag.html.erb",
      :code => s(:call, nil, :content_tag, s(:lit, :div), s(:str, "Blah!"), s(:hash, s(:lit, :class), s(:call, s(:params), :[], s(:lit, :class))), s(:true)),
      :user_input => s(:call, s(:params), :[], s(:lit, :class))
  end 

  def test_cross_site_scripting_model_in_tag_name
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 35,
      :message => /^Unescaped\ model\ attribute\ in\ `content_tag`/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_content_tag_attributes_CVE_2016_6316
    assert_warning :type => :template,
      :warning_code => 53,
      :fingerprint => "e1d77d0c162fb0a1c4cc55655045755217c9e46f575d5c89848cfa2207fd1406",
      :warning_type => "Cross-Site Scripting",
      :line => 23,
      :message => /^Unescaped\ parameter\ value\ in\ `content_tag`/,
      :confidence => 0,
      :relative_path => "app/views/home/test_content_tag.html.erb",
      :code => s(:call, nil, :content_tag, s(:lit, :div), s(:str, "Blah!"), s(:hash, s(:lit, :class), s(:call, s(:params), :[], s(:lit, :class)))),
      :user_input => s(:call, s(:params), :[], s(:lit, :class))
  end

  def test_cross_site_scripting_request_parameters
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 20,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_cross_site_scripting_in_nested_controller
    assert_warning :type => :template,
      :warning_code => 2,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /so_nested\.html\.erb/
  end

  def test_cross_site_scripting_from_parent
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "1e860da2c9a0cac3d898f3c4327877b3bdfa391048a19bfd6f55d6e283cc5b33",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/child/action_in_child.html.erb"
  end

  def test_cross_site_scripting_select_tag_CVE_2012_3463
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Upgrade\ to\ Rails\ 3\.0\.17\. In Rails 3\.0\.3\ `select_ta/,
      :confidence => 0,
      :file => /test_select_tag\.html\.erb/
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :message => /^Rails\ 3\.0\.3\ does\ not\ escape\ single\ quote/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_CVE_2012_3424
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^Vulnerability\ in\ digest\ authentication\ \(/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_strip_tags_CVE_2012_3465
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :message => /^Versions\ before\ 3\.0\.10\ have\ a\ vulnerabil/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_mail_link_CVE_2011_0446
    assert_warning :type => :template,
      :warning_code => 32,
      :fingerprint => "0102737200d60593b78d62a93bd19fbced21fe017ec20c738104cc55afb551bb",
      :warning_type => "Mail Link",
      :line => 1,
      :message => /^Vulnerability\ in\ `mail_to`\ using\ javascr/,
      :confidence => 0,
      :relative_path => "app/views/other/test_mail_to.html.erb"
  end

  def test_sql_injection_CVE_2013_0155
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2013-0155/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_remote_code_execution_CVE_2013_0156_fix
    assert_no_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 3\.0\.3\ has\ a\ remote\ code\ execution\ /,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_remote_code_execution_CVE_2013_0277_protected
    assert_warning :type => :model,
      :warning_type => "Remote Code Execution",
      :message => /^Serialized\ attributes\ are\ vulnerable\ in\ /,
      :confidence => 1,
      :file => /product\.rb/
  end

  def test_remote_code_execution_CVE_2013_0277_accessible
    assert_warning :type => :model,
      :warning_type => "Remote Code Execution",
      :message => /^Serialized\ attributes\ are\ vulnerable\ in\ /,
      :confidence => 1,
      :file => /purchase\.rb/
  end

  def test_remote_code_execution_CVE_2013_0277_unprotected
    assert_warning :type => :model,
      :fingerprint => "b85602475eb048cfe7941b5952c3d5a09a7d9d0607f81fbf2b7578d1055fec90",
      :warning_type => "Remote Code Execution",
      :message => /^Serialized\ attributes\ are\ vulnerable\ in\ /,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_remote_code_execution_CVE_2013_0333
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 3\.0\.3\ has\ a\ serious\ JSON\ parsing\ v/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_0269
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^json_pure gem\ 1\.6\.4\ has\ a\ symbol/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_xss_CVE_2013_1857
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :line => 40,
      :message => /^Rails\ 3\.0\.3\ has\ a\ vulnerability\ in\ `sanit/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_xml_jruby_parsing_CVE_2013_1856
    if RUBY_PLATFORM == 'java'
      assert_warning :type => :warning,
        :warning_type => "File Access",
        :message => /^Rails\ 3\.0\.3\ with\ JRuby\ has\ a\ vulnerabili/,
        :confidence => 0,
        :file => /Gemfile/
    end
  end

  def test_denial_of_service_CVE_2013_1854
    assert_no_warning :type => :warning,
      :warning_code => 55,
      :fingerprint => "2746b8872d4f46676a8c490a7ac906d23f6b11c9d83b6371ff5895139ec7b43b",
      :warning_type => "Denial of Service",
      :message => /^Rails\ 3\.0\.3\ has\ a\ denial\ of\ service\ vul/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_6414
    assert_warning :type => :warning,
      :warning_code => 64,
      :fingerprint => "ee4938ce7bc4aa6f37b3d993d6fed813de6b15e5c1ada41146563207c395b0c5",
      :warning_type => "Denial of Service",
      :message => /^Rails\ 3\.0\.3\ has\ a\ denial\ of\ service\ vuln/,
      :confidence => 1,
      :line => 49,
      :relative_path => "Gemfile.lock"
  end

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :warning,
      :warning_code => 73,
      :fingerprint => "86f945934ed965a47c30705141157c44ee5c546d044f8de7d573bfab456e97ce",
      :warning_type => "Cross-Site Scripting",
      :line => 49,
      :message => /^Rails\ 3\.0\.3\ has\ a\ vulnerability\ in\ numbe/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "2f63d663e9f35ba60ef81d56ffc4fbf0660fbc2067e728836176bc18f610f77f",
      :warning_type => "SQL Injection",
      :line => 49,
      :file => /Gemfile.lock/,
      :message => /^Rails\ 3\.0\.3\ contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_denial_of_service_CVE_2014_0082
    assert_warning :type => :warning,
      :warning_code => 75,
      :fingerprint => "99b6df435353f17dff4b0d7dfeb5f21e5c0e8045dc73533e456baf78f1fc2215",
      :warning_type => "Denial of Service",
      :line => 49,
      :message => /^Rails\ 3\.0\.3\ has\ a\ denial\ of\ service\ vuln/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_remote_code_execution_CVE_2014_0130
    assert_warning :type => :warning,
      :warning_code => 77,
      :fingerprint => "93393e44a0232d348e4db62276b18321b4cbc9051b702d43ba2fd3287175283c",
      :warning_type => "Remote Code Execution",
      :line => nil,
      :message => /^Rails\ 3\.0\.3\ with\ globbing\ routes\ is\ vuln/,
      :confidence => 0,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end

  def test_http_only_session_setting
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 3,
      :message => /^Session\ cookies\ should\ be\ set\ to\ HTTP\ on/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_secure_only_session_setting
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 3,
      :message => /^Session\ cookie\ should\ be\ set\ to\ secure\ o/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_session_secret_token
    assert_no_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 7,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /secret_token\.rb/
  end

  def test_remote_code_execution_yaml_load_params_interpolated
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 106,
      :message => /^`YAML\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_remote_code_execution_yaml_load_params
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 123,
      :message => /^`YAML\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_remote_code_execution_yaml_load_indirect_cookies
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 125,
      :message => /^`YAML\.load`\ called\ with\ cookie\ value/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_remote_code_execution_yaml_load_model_attribute
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 126,
      :message => /^`YAML\.load`\ called\ with\ model\ attribute/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_remote_code_execution_yaml_load_documents
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 130,
      :message => /^`YAML\.load_documents`\ called\ with\ paramete/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end


  def test_remote_code_execution_yaml_load_stream
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 131,
      :message => /^`YAML\.load_stream`\ called\ with\ cookie\ value/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end


  def test_remote_code_execution_yaml_parse_documents
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 132,
      :message => /^`YAML\.parse_documents`\ called\ with\ paramet/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end


  def test_remote_code_execution_yaml_parse_stream
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 133,
      :message => /^`YAML\.parse_stream`\ called\ with\ model\ attr/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_CVE_2015_3227
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "ab42647fbdea61e25c4b794e82a8b315054e2fac4328bb3fd4be6a744889a987",
      :warning_type => "Denial of Service",
      :line => 49,
      :message => /^Rails\ 3\.0\.3\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_denial_of_service_CVE_2015_7576
    assert_warning :type => :warning,
      :warning_code => 94,
      :fingerprint => "5945a9b096557ee5771c2dd12ea6cbec933b662d169e559f524ba01c44bf2452",
      :warning_type => "Denial of Service",
      :line => 49,
      :message => /^Rails\ 3\.0\.3\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2016_6316_Gemfile
    assert_warning :type => :warning,
      :warning_code => 102,
      :fingerprint => "331e69e4654f158601d9a0e124304f825da4e0156d2c94759eb02611e280feaa",
      :warning_type => "Cross-Site Scripting",
      :line => 49,
      :message => /^Rails\ 3\.0\.3\ `content_tag`\ does\ not\ escape\ /,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_unmaintained_dependency_rails
    assert_warning check_name: "EOLRails",
      type: :warning,
      warning_code: 120,
      fingerprint: "d84924377155b41e094acae7404ec2e521629d86f97b0ff628e3d1b263f8101c",
      warning_type: "Unmaintained Dependency",
      line: 49,
      message: /^Support\ for\ Rails\ 3\.0\.3\ ended\ on\ 2016\-06/,
      confidence: 0,
      relative_path: "Gemfile.lock",
      code: nil,
      user_input: nil
  end
end
