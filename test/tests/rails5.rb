require_relative '../test'

class Rails5Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails5", "Rails 5", run_all_checks: true
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 10,
      :generic => 19
    }
  end

  def test_mass_assignment_with_safe_attrasgn
    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "046f3c6cc9a55464d21837b583c672c26532cd46c1f719853a1a15b790baf8ea",
      :warning_type => "Mass Assignment",
      :line => 78,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:params), :permit!),
      :user_input => nil
  end

  def test_mass_assignment_with_slice
    assert_no_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "79c472e032f2ff16f4688ea9d87ccc1c6def392c9b3e189ee1c4d1c079dd4fbf",
      :warning_type => "Mass Assignment",
      :line => 87,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, s(:params), :slice, s(:lit, :id)), :permit!),
      :user_input => nil
  end

  def test_mass_assignment_permit_high
    assert_warning :type => :warning,
      :warning_code => 105,
      :fingerprint => "615627822842388859734b6124bf99e0db057a2572f35c92ff42b5ad46f4415f",
      :warning_type => "Mass Assignment",
      :line => 90,
      :message => /^Potentially\ dangerous\ key\ allowed\ for\ ma/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:call, s(:params), :permit, s(:lit, :admin)),
      :user_input => s(:lit, :admin)
  end

  def test_mass_assignment_permit_medium
    assert_no_warning :type => :warning,
      :warning_code => 105,
      :fingerprint => "c4c89a39b0a2dc707027f47747312d27308ea219a009e4f0116a759a71ad561b",
      :warning_type => "Mass Assignment",
      :line => 91,
      :message => /^Potentially\ dangerous\ key\ allowed\ for\ ma/,
      :confidence => 1,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:call, s(:params), :permit, s(:lit, :role_id)),
      :user_input => s(:lit, :role_id)
  end

  def test_sql_injection_with_slice
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "d9f4fec5f738785ea1aed229d192a2d5d2eb0d8805f6ca58fd02416105e0f9db",
      :warning_type => "SQL Injection",
      :line => 88,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :User), :find_by, s(:call, s(:params), :slice, s(:lit, :id))),
      :user_input => s(:call, s(:params), :slice, s(:lit, :id))
  end

  def test_sql_injection_with_quoted_primary_key
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "f9396dd572315e802eca1e03024a5b309ff006ede47b1aef6255236fcc37d2a9",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/thing.rb",
      :user_input => s(:call, nil, :quoted_primary_key)
  end

  def test_divide_by_zero_1
    assert_warning :type => :warning,
      :warning_code => 104,
      :fingerprint => "f0729f7446e41e51883e58c74aa0789c0c7a48ab832f16c17b7eaba01a21ce6e",
      :warning_type => "Divide by Zero",
      :line => 8,
      :message => /^Potential\ division\ by\ zero/,
      :confidence => 2,
      :relative_path => "lib/a_lib.rb",
      :code => s(:call, s(:call, nil, :whatever), :/, s(:lit, 0)),
      :user_input => s(:lit, 0)
  end

  def test_divide_by_zero_2
    assert_warning :type => :warning,
      :warning_code => 104,
      :fingerprint => "9ca769ad11ef57b7490caccc70af1bb8a623dfca2e84e5593d8dec901d3841f2",
      :warning_type => "Divide by Zero",
      :line => 12,
      :message => /^Potential\ division\ by\ zero/,
      :confidence => 1,
      :relative_path => "lib/a_lib.rb",
      :code => s(:call, s(:lit, 100), :/, s(:lit, 0)),
      :user_input => s(:lit, 0)
  end

  def test_dangerous_send_with_safe_call
    assert_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "21c9eef1c001e48a0bfedfa11ff0f9d96b0c106f1016218712dabc088b2e69b6",
      :warning_type => "Dangerous Send",
      :line => 76,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, nil, :x), :send, s(:call, s(:params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_dangerous_send_with_early_return
    assert_no_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "04f96cff9e890ab6c0a54c62465602eb92fe74f4fb91c10dcad51aaeb96ff7d7",
      :warning_type => "Dangerous Send",
      :line => 16,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/mixed_controller.rb",
      :code => s(:call, s(:colon2, s(:const, :Statistics), :AdminWithdrawal), :send, s(:dstr, "export_", s(:evstr, s(:call, s(:call, s(:params), :[], s(:lit, :filename)), :first)), s(:str, "_#inc!"))),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :filename)), :first)
  end

  def test_dangerous_send_with_fail
    assert_no_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "e39bb04370762208b68068f4dc823ec897b75bb50f4a5dee02e329e2b6dda733",
      :warning_type => "Dangerous Send",
      :line => 22,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/mixed_controller.rb",
      :code => s(:call, s(:const, :Model), :public_send, s(:call, s(:call, s(:params), :[], s(:lit, :scope)), :presence)),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :scope)), :presence)
  end

  def test_no_symbol_denial_of_service
    assert_no_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "78ba8fe2efc151bc8eca64f36940d1423a8fb92f17a8b7858bffba6cb372490b",
      :warning_type => "Denial of Service",
      :line => 83,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, s(:params), :[], s(:lit, :x)), :to_sym),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_secrets_in_source
    assert_warning :type => :warning,
      :warning_code => 101,
      :fingerprint => "eefde7320af81299c41d50840750b5cb509a1fe454ba9179076955bf53b6d966",
      :warning_type => "Authentication",
      :line => 1,
      :message => /^Hardcoded\ value\ for\ DB_PASSWORD\ in\ sourc/,
      :confidence => 1,
      :user_input => nil,
      :relative_path => "config/initializers/secrets.rb"
  end

  def test_skipping_rails_env_test
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "46cda22e00dca87a8715682bd7d8d52cc4a8e705257b27c5e36595ebd1f654f8",
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:const, :User), :where, s(:params)),
      :user_input => s(:params)
  end

  def test_default_routes_in_test
    assert_no_warning :type => :warning,
      :warning_code => 11,
      :fingerprint => "ff2b76e22c9fd2bc3930f9a935124b9ed9f6ea710bbb5bc7c51505d70ca0f2d5",
      :warning_type => "Default Routes",
      :line => 8,
      :message => /^All\ public\ methods\ in\ controllers\ are\ av/,
      :confidence => 0,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end

  def test_redirect_with_slice
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "b70fe6fa14df927bdfe80e0731c4c4170db0c3c80edad5a4462c7037acde93a4",
      :warning_type => "Redirect",
      :line => 89,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:params), :slice, s(:lit, :back_to))),
      :user_input => s(:call, s(:params), :slice, s(:lit, :back_to))
  end

  def test_redirect_with_return_guard
    assert_no_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "208deedcfef17a235e5c2139c74bbb408b2a948334880be58fcc441c09b9d799",
      :warning_type => "Dangerous Send",
      :line => 82,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:call, nil, :send, s(:dstr, "", s(:evstr, s(:call, s(:params), :[], s(:lit, :goto))), s(:str, "_event_path")), s(:call, s(:params), :[], s(:lit, :event))),
      :user_input => s(:call, s(:params), :[], s(:lit, :goto))
  end

  def test_redirect_with_unsafe_permit_values
    assert_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "9187972b879413888afcc0f94c02d9e5c47d56ecb15add404d6706f95efc08ee",
      :warning_type => "Redirect",
      :line => 26,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/mixed_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:params), :permit, s(:lit, :domain))),
      :user_input => s(:call, s(:params), :permit, s(:lit, :domain))
  end

  def test_redirect_with_safe_permit_values
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "b148908432d722a877a87c9c70e62cdf67328a2f25f6f62eefebce94ef01b7ec",
      :warning_type => "Redirect",
      :line => 27,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/mixed_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:params), :permit, s(:lit, :page), s(:lit, :sort))),
      :user_input => s(:call, s(:params), :permit, s(:lit, :page), s(:lit, :sort))
  end

  def test_redirect_with_path_on_model
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "1f0dba58823930667b1fbf060329a5ce7462b517b776d1985da014321f399362",
      :warning_type => "Redirect",
      :line => 100,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:call, s(:call, s(:const, :User), :find_by_token, s(:call, s(:params), :[], s(:lit, :session))), :user), :current_path)),
      :user_input => s(:call, s(:call, s(:call, s(:const, :User), :find_by_token, s(:call, s(:params), :[], s(:lit, :session))), :user), :current_path)
  end

  def test_cross_site_scripting_with_slice
    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "0e7c3fed684f3152150e01986fbdde92741b2d69628156f3f28f30987456c018",
      :warning_type => "Cross-Site Scripting",
      :line => 25,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "slice"), s(:call, s(:params), :slice, s(:lit, :url))),
      :user_input => s(:call, s(:params), :slice, s(:lit, :url))
  end

  def test_cross_site_scripting_with_merge_in_link_to
    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "54043efc2da20930f636dedfef5b1e77dfed0957ebb0c285f0c0a71b68e046c5",
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "good"), s(:call, s(:call, nil, :params), :merge, s(:hash, s(:lit, :page), s(:lit, 2)))),
      :user_input => s(:call, s(:call, nil, :params), :merge, s(:hash, s(:lit, :page), s(:lit, 2)))
  end

  def test_cross_site_scripting_link_to_url_for
    assert_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "03fcddff701f15c976a229c2a814c817f81463b733c6d4925253488879d907e3",
      :warning_type => "Cross-Site Scripting",
      :line => 7,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "xss"), s(:call, nil, :url_for, s(:call, s(:params), :[], s(:lit, :bad)))),
      :user_input => s(:call, s(:params), :[], s(:lit, :bad))
  end

  def test_cross_site_scripting_inline_erb
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "26b8b0ad586712d41ac6877e2292c6da7aa4760078add7fd23edf5b7a1bcb699",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/widget/show.html.erb",
      :code => s(:call, s(:params), :[], s(:lit, :x)),
      :user_input => nil
  end

  def test_cross_site_scripting_in_layout
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "7aec2bbe8fa40f49f08b70dfc8c0b6afdc9be252eb0459a3d5313bc904d9ec77",
      :warning_type => "Cross-Site Scripting",
      :line => 2,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/layouts/users.html.erb",
      :code => s(:call, s(:call, s(:const, :User), :new), :name),
      :user_input => nil
  end

  def test_cross_site_scripting_in_template_with_no_html_extension
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "dbec030dda82f21c5ea860e38746de64a6f3b9c49508ae2db947759a753a386c",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/widget/no_html.haml",
      :code => s(:call, s(:params), :[], s(:lit, :x)),
      :user_input => nil
  end

  def test_if_expression_in_templates
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "26b8b0ad586712d41ac6877e2292c6da7aa4760078add7fd23edf5b7a1bcb699",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/widget/show.html.erb",
      :code => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_remote_code_execution_in_dynamic_constant
    assert_warning :type => :warning,
      :warning_code => 24,
      :fingerprint => "ed9f1dea97ba2929a0107fce64c3b4aa66010961ebbef36e1d11428067095cb6",
      :warning_type => "Remote Code Execution",
      :line => 7,
      :message => /^Unsafe\ reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:call, s(:call, s(:params), :[], s(:lit, :IdentifierClass)), :constantize),
      :user_input => s(:call, s(:params), :[], s(:lit, :IdentifierClass))
  end

  def test_dynamic_render_path_with_boolean
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "77503a2c10167a42ac4b40b81aa2cf3b737ad206f5a9c593ae9898c9915a5136",
      :warning_type => "Dynamic Render Path",
      :line => 11,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:render, :action, s(:call, s(:call, s(:params), :[], s(:lit, :x)), :thing?), s(:hash)),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :x)), :thing?)
  end

  def test_dynamic_render_path_template_exists
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "5c250fd85fe088bf628d517af37038fa516acc4b6103ee6d8a15e857079ad434",
      :warning_type => "Dynamic Render Path",
      :line => 108,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:render, :action, s(:call, s(:call, s(:params), :[], s(:lit, :slug)), :to_s), s(:hash)),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :slug)), :to_s)
  end

  def test_render_inline_cookies
    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "8badd2e174576484eca32fb6015d903700d6694e9b3486be64d737aa215a36ea",
      :warning_type => "Cross-Site Scripting",
      :line => 86,
      :message => /^Unescaped\ cookie\ value\ rendered\ inline/,
      :confidence => 0,
      :relative_path => "app/controllers/widget_controller.rb",
      :code => s(:render, :inline, s(:call, s(:call, s(:call, nil, :request), :cookies), :[], s(:str, "value")), s(:hash)),
      :user_input => s(:call, s(:call, s(:call, nil, :request), :cookies), :[], s(:str, "value"))
  end

  def test_warning_in_helper_method
    assert_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "e90f8e364e35ed2f6a56b4597e7de8945c836c75ef673006d960a380ecdf47e8",
      :warning_type => "Dangerous Eval",
      :line => 3,
      :message => /^User\ input\ in\ eval/,
      :confidence => 0,
      :relative_path => "app/helpers/users_helper.rb",
      :code => s(:call, nil, :eval, s(:call, s(:params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_where_values_hash_fp
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "2a77f56c4c09590a4cac1fe68dd00c0fa0a7820ea6f0d4bad20451ecc07dc68e",
      :warning_type => "SQL Injection",
      :line => 17,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => s(:call, nil, :where, s(:call, s(:call, s(:const, :Thing), :canadian), :where_values_hash)),
      :user_input => s(:call, s(:call, s(:const, :Thing), :canadian), :where_values_hash)
  end

  def test_sql_injection_from_model_call_fp
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "dcfa0c30b2d303c58bde5b376f423cff6282bbc71ed460077478ca97e1f4d0f7",
      :warning_type => "SQL Injection",
      :line => 20,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:const, :User), :where, s(:call, s(:const, :User), :access_condition, s(:lvar, :user))),
      :user_input => s(:call, s(:const, :User), :access_condition, s(:lvar, :user))
  end

  def test_targetless_sql_injection_outside_of_AR_model
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "fe0098fc5ab1051854573b487855f348bd9320c8eb5ae55302b4649d0147d7dd",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "lib/a_lib.rb",
      :code => s(:call, nil, :joins, s(:dstr, "INNER JOIN things ON id = ", s(:evstr, s(:call, s(:params), :[], s(:lit, :id))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :id))
  end

  def test_sql_injection_in_interp_branch
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "13c2dbdbce47c04755e5019dba4fc03729167c71a63e1d4bab81d672ff3975a0",
      :warning_type => "SQL Injection",
      :line => 93,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, s(:const, :User), :connection), :execute, s(:dstr, "SELECT * FROM foo WHERE ", s(:evstr, s(:if, s(:true), s(:dstr, "bar = ", s(:evstr, s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :quote, s(:true)))), nil)))),
      :user_input => s(:if, s(:true), s(:dstr, "bar = ", s(:evstr, s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :quote, s(:true)))), nil)
  end

  def test_sql_injection_arel_sql
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "672fb59ead203af7b429e4efa722101b9246e60334470daa7c07a62078974350",
      :warning_type => "SQL Injection",
      :line => 97,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Arel), :sql, s(:dstr, "select ", s(:evstr, s(:call, s(:params), :[], s(:lit, :s))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :s))
  end

  def test_tempfile_access
    assert_no_warning :type => :warning,
      :warning_code => 16,
      :fingerprint => "4c1ffee385f7f0318d609a3675b13d9eeaf6da3ce6a7953df523c7d6ba4d24b5",
      :warning_type => "File Access",
      :line => 8,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :relative_path => "lib/a_lib.rb",
      :code => s(:call, s(:const, :FileUtils), :move, s(:call, s(:call, s(:call, s(:call, s(:params), :permit, s(:hash, s(:lit, :my_upload), s(:array, s(:lit, :upload)))), :dig, s(:str, "my_upload"), s(:str, "upload")), :tempfile), :path), s(:str, "/tmp/new_temp_file")),
      :user_input => s(:call, s(:call, s(:call, s(:call, s(:params), :permit, s(:hash, s(:lit, :my_upload), s(:array, s(:lit, :upload)))), :dig, s(:str, "my_upload"), s(:str, "upload")), :tempfile), :path)

    assert_no_warning :type => :warning,
      :warning_code => 16,
      :fingerprint => "9783fd98e5657e76e8337bc7b319b101e8cf5ab3b290d69d5f00eee3a86e4ebd",
      :warning_type => "File Access",
      :line => 9,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :relative_path => "lib/a_lib.rb",
      :code => s(:call, s(:const, :FileUtils), :move, s(:call, s(:call, s(:call, s(:params), :permit, s(:hash, s(:lit, :my_upload), s(:array, s(:lit, :upload)))), :dig, s(:str, "my_upload"), s(:str, "upload")), :path), s(:str, "/tmp/new_temp_file")),
      :user_input => s(:call, s(:call, s(:call, s(:params), :permit, s(:hash, s(:lit, :my_upload), s(:array, s(:lit, :upload)))), :dig, s(:str, "my_upload"), s(:str, "upload")), :path)
  end

  def test_cross_site_scripting_CVE_2015_7578
    assert_warning :type => :warning,
      :warning_code => 96,
      :fingerprint => "7feea01d5ef6edbc300e34ecffd304a4d76cf306dbc71712a8340a3ac08b6dad",
      :warning_type => "Cross-Site Scripting",
      :line => 133,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2015_7580
    assert_warning :type => :warning,
      :warning_code => 97,
      :fingerprint => "f542035c0310ab2e76ec6dbccace0954f0d7c576d56d8cfcb03d9836f50bc7c9",
      :warning_type => "Cross-Site Scripting",
      :line => 133,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2015_7579
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "0d980d69bd0158cfa6a92c12bc49294fe32e9862a758e11fe3cf9e03b6c50489",
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/sanitizing.html.erb",
      :code => s(:call, nil, :strip_tags, s(:call, s(:call, nil, :params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_sanitize_cve
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "e203c837d65aad6ab63e09c2487beabf478534f77f0c20e946a28a38826ca657",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/sanitizing.html.erb",
      :code => s(:call, nil, :sanitize, s(:call, s(:call, nil, :params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_strip_tags_cve
    assert_warning :type => :warning,
      :warning_code => 98,
      :fingerprint => "9f292c507e0f07fd0ffc7a3d000af464c522ae6a929015256f505f35fb75ac82",
      :warning_type => "Cross-Site Scripting",
      :line => 115,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_xss_content_tag_CVE_2016_6316_html_safe
    assert_warning :type => :template,
      :warning_code => 53,
      :fingerprint => "956e3e4f494316c5f30cde009086fd7be0bddf80d85901cdb8e3d7b7d76d219b",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 0,
      :relative_path => "app/views/widget/content_tag.html.erb",
      :code => s(:call, nil, :content_tag, s(:lit, :div), s(:str, "hi"), s(:hash, s(:lit, :title), s(:call, s(:call, s(:call, nil, :params), :[], s(:lit, :stuff)), :html_safe))),
      :user_input => s(:call, s(:call, s(:call, nil, :params), :[], s(:lit, :stuff)), :html_safe)
  end

  def test_xss_content_tag_CVE_2016_6316_sanitize
    assert_warning :type => :template,
      :warning_code => 53,
      :fingerprint => "a1ca8c0e91d159ddc920d3c9efc6942f6aa697c519b299b756810ac1ca977763",
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 1,
      :relative_path => "app/views/widget/content_tag.html.erb",
      :code => s(:call, nil, :content_tag, s(:lit, :div), s(:str, "hi"), s(:hash, s(:lit, :title), s(:call, nil, :sanitize, s(:call, s(:call, nil, :params), :[], s(:lit, :stuff))))),
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :stuff))
  end

  def test_cross_site_scripting_CVE_2016_6316_general
    assert_warning :type => :warning,
      :warning_code => 102,
      :fingerprint => "331e69e4654f158601d9a0e124304f825da4e0156d2c94759eb02611e280feaa",
      :warning_type => "Cross-Site Scripting",
      :line => 115,
      :message => /^Rails\ 5\.0\.0\ content_tag\ does\ not\ escape\ /,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_loofah_CVE_2018_8048
    assert_warning :type => :warning,
      :warning_code => 106,
      :fingerprint => "cdfb1541fdcc9cdcf0784ce5bd90013dc39316cb822eedea3f03b2521c06137f",
      :warning_type => "Cross-Site Scripting",
      :line => 99,
      :message => /^Loofah\ 2\.0\.3\ is\ vulnerable\ \(CVE\-2018\-804/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2018_3741
    assert_warning :type => :warning,
      :warning_code => 107,
      :fingerprint => "3e35a6afcd1a8a14894cf26a7f00d4e895f0583bbc081d45e5bd28c4b541b7e6",
      :warning_type => "Cross-Site Scripting",
      :line => 133,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_dangerous_eval_in_prior_class_method_with_same_name
    assert_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "7fe3142d1d11b7118463e45a82b4b7a2b5b5bac95cf8904050c101fae16b8168",
      :warning_type => "Dangerous Eval",
      :line => 3,
      :message => /User input in eval near line 3/,
      :method => :"User.evaluate_user_input",
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :user_input => s(:params)
  end

  def test_link_to_href_safe_interpolation
    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "840e79fc7cc526a9e744b8a3d49f6689aa572941f46b030d14cdec01f3675a4a",
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/widget/show.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "Thing"), s(:dstr, "", s(:evstr, s(:call, s(:const, :ENV), :[], s(:str, "SOME_URL"))), s(:evstr, s(:call, s(:params), :[], s(:lit, :x))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))

    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "ea91f7cfb339ae9522f00fb1f3bc176f789110b6e0cbc4f8704e95d0999b0e71",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/widget/show.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "Email!"), s(:dstr, "mailto:", s(:evstr, s(:call, s(:params), :[], s(:lit, :x))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_sanitize_in_link_to
    assert_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "2247b0928591e951ddb428e97bf4174a36080a196a2f6d6fedd2d7c4428db2a9",
      :warning_type => "Cross-Site Scripting",
      :line => 9,
      :message => /^Potentially\ unsafe\ model\ attribute\ in\ li/,
      :confidence => 2,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, nil, :link_to, s(:call, nil, :image_tag, s(:str, "icons/twitter-gray.svg")), s(:call, nil, :sanitize, s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :home_page)), s(:hash, s(:lit, :target), s(:str, "_blank"))),
      :user_input => s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :home_page)
  end

  def test_mixed_in_csrf_protection
    assert_no_warning :type => :controller,
      :warning_type => "Cross-Site Request Forgery",
      :line => 1,
      :message => /^'protect_from_forgery'\ should\ be\ called\ /,
      :relative_path => "app/controllers/mixed_controller.rb"
  end

  def test_unscoped_find
    assert_no_warning :type => :warning,
      :warning_code => 82,
      :fingerprint => "21a836b647ac118baf1a63e5fa4c219f8d600760b05ff9b8927c39a97ebf1dd1",
      :warning_type => "Unscoped Find",
      :line => 67,
      :message => /^Unscoped\ call\ to\ User\#find/,
      :confidence => 2,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :User), :find, s(:call, s(:params), :[], s(:lit, :id))),
      :user_input => s(:call, s(:params), :[], s(:lit, :id))
  end
end
