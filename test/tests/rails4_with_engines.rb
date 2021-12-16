require_relative '../test'

class Rails4WithEnginesTests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 2,
      :model => 5,
      :template => 12,
      :generic => 15 }
  end

  def report
   @@report ||= BrakemanTester.run_scan "rails4_with_engines", "Rails4WithEngines"
  end

  def test_dangerous_send_in_engine
    assert_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "d32b6adf5f606b101ff7e1d47d76458f84fc8e3b5fbed7a7347fe7ae34cde9bb",
      :warning_type => "Dangerous Send",
      :line => 3,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "alt_engines/admin_stuff/app/controllers/admin_controller.rb",
      :code => s(:call, s(:call, s(:call, s(:call, s(:params), :[], s(:lit, :class)), :classify), :constantize), :send, s(:call, s(:params), :[], s(:lit, :meth))),
      :user_input => s(:call, s(:params), :[], s(:lit, :meth))
  end

  def test_cross_site_scripting_in_engine
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "2cdecf9256c975d1c7a3cdb0f912eb8f660b8b5a9e343dd8f6e7e73c827b7549",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "alt_engines/admin_stuff/app/views/admin/debug.html.erb",
      :code => s(:call, s(:params), :[], s(:lit, :debug)),
      :user_input => nil
  end

  def test_remote_code_execution_in_engine
    assert_warning :type => :warning,
      :warning_code => 24,
      :fingerprint => "5a59773cc5a29469202c4e8908e37cdb9ef7926af05f68de1c6e765854e869c0",
      :warning_type => "Remote Code Execution",
      :line => 3,
      :message => /^Unsafe\ reflection\ method\ `constantize`\ cal/,
      :confidence => 0,
      :relative_path => "alt_engines/admin_stuff/app/controllers/admin_controller.rb",
      :code => s(:call, s(:call, s(:call, s(:params), :[], s(:lit, :class)), :classify), :constantize),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :class)), :classify)
  end

  def test_i18n_xss_CVE_2013_4491
    assert_warning :type => :warning,
      :warning_code => 63,
      :fingerprint => "f127f5b2c0fc6f49570a6a3ec2b79baa2d8c24df59f86926f7a83855af06f534",
      :warning_type => "Cross-Site Scripting",
      :message => /^Rails\ 4\.0\.0\ has\ an\ XSS\ vulnerability\ in\ /,
      :file => /gems.rb/,
      :confidence => 1,
      :relative_path => "gems.rb"
  end

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :warning,
      :warning_code => 73,
      :fingerprint => "d884628b046c0ac6267bffe01bf0017a29dd94065e10e564d337cd85e40550a1",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.0\.0\ has\ a\ vulnerability\ in\ numbe/,
      :confidence => 1,
      :relative_path => "gems.rb",
      :user_input => nil
  end

  def test_xss_simple_format_CVE_2013_6416
    assert_warning :type => :template,
      :warning_code => 68,
      :fingerprint => "e5b270bcb5bf77069b7e4adf0c46221d1277f0b126c795e43b700a6b0f4747ae",
      :warning_type => "Cross-Site Scripting",
      :line => 20,
      :message => /^Values\ passed\ to\ `simple_format`\ are\ not\ s/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/show.html.erb",
      :user_input => s(:call, s(:call, s(:const, :User), :find, s(:call, s(:params), :[], s(:lit, :id))), :likes)

    assert_warning :type => :template,
      :warning_code => 68,
      :fingerprint => "e31d9365f0e99e55bb3d62deda2bf1ee0bc4e5970dd5791fcde8056f6558f51f",
      :warning_type => "Cross-Site Scripting",
      :line => 21,
      :message => /^Values\ passed\ to\ `simple_format`\ are\ not\ s/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/show.html.erb",
      :user_input => s(:call, s(:params), :[], s(:lit, :color))
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "6526cbe210b51803986cddbfd567059c8036390eb697d64baa604b62940a3c55",
      :warning_type => "SQL Injection",
      :message => /^Rails\ 4\.0\.0\ contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => 'gems.rb',
      :line => 4,
      :file => /gems.rb/,
      :user_input => nil
  end

  def test_remote_code_execution_CVE_2014_0130
    assert_warning :type => :warning,
      :warning_code => 77,
      :fingerprint => "e833fd152ab95bf7481aada185323d97cd04c3e2322b90f3698632f4c4c04441",
      :warning_type => "Remote Code Execution",
      :line => nil,
      :message => /^Rails\ 4\.0\.0\ with\ globbing\ routes\ is\ vuln/,
      :confidence => 1,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end

  def test_mass_assignment_CVE_2014_3514
    assert_warning :type => :warning,
      :warning_code => 80,
      :fingerprint => "98c76e0940c4e2ebb0dafd2b022c6818e7f620f196ce7e5c612af7d6ac06cd39",
      :warning_type => "Mass Assignment",
      :line => 4,
      :message => /^`create_with`\ is\ vulnerable\ to\ strong\ para/,
      :confidence => 1,
      :relative_path => "gems.rb",
      :user_input => nil
  end

  def test_redirect_1
    assert_warning :type => :generic,
      :warning_code => 18,
      :fingerprint => "6d27826e07e583ba9c6ae1f33843089fd1d8b1a2c359e00bf636e64a85a47feb",
      :warning_type => "Redirect",
      :line => 14,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/controllers/removal_controller.rb"
  end

  def test_session_setting_2
    assert_warning :type => :generic,
      :warning_code => 29,
      :fingerprint => "715ad9c0d76f57a6a657192574d528b620176a80fec969e2f63c88eacab0b984",
      :warning_type => "Session Setting",
      :line => 12,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :relative_path => "config/initializers/secret_token.rb"
  end

  def test_cross_site_scripting_3
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "598b957fea4a202a75e1d8101a8c21332b10b2c0e9ca4ffad6c18407bde6615d",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/removal/_partial.html.erb"
  end

  def test_cross_site_scripting_4
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "011d330ea62763eb61684cccc4169518b0876eadbab2b469e3526548f3da3795",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/removal/controller_removed.html.erb"
  end

  def test_cross_site_scripting_5
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "26da712dc3289b873b7928b54bde6da038cbf891ec11076897e062f32939863e",
      :warning_type => "Cross-Site Scripting",
      :line => 2,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/removal/implicit_render.html.erb"
  end

  def test_cross_site_scripting_6
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "52c513069319d44e03c5ac21806d47c1f05393fe35a5026314c8064f70ff0375",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/_form.html.erb"
  end

  def test_cross_site_scripting_7
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "9d94ba6993f761ff688b5a8d428c793486cd8bf42f487a44d895a96f658dca50",
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/_slimmer.html.slim"
  end

  def test_cross_site_scripting_8
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "9d576795978cf6681a0cd17f7250ea267ab2ac7888dd5f6100331d5c0684beb3",
      :warning_type => "Cross-Site Scripting",
      :line => 8,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/_slimmer.html.slim"
  end

  def test_cross_site_scripting_9
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "822a9a031ab38ae9e2b3580ce6eb28e6372852f289c9e65b347a9182c918d551",
      :warning_type => "Cross-Site Scripting",
      :line => 15,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/show.html.erb"
  end

  def test_cross_site_scripting_10
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "aa06d3e4d8e00ccf6169d9293b1ef90365917c46fa21678d248494f7767d1d15",
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/slimming.html.slim"
  end

  def test_cross_site_scripting_11
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "6628d5e2059d14b31e7c37251ac7380ddbe44e937d78d4e955763d5d53df08fc",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/views/users/slimming.html.slim"
  end

  def test_mass_assignment_12
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "dbb51200329e5eadf073c7145497d0b18e33d903248426b6e8b97ec5d03ec23a",
      :warning_type => "Mass Assignment",
      #noline,
      :message => "Potentially dangerous attribute available for mass assignment: :plan_id",
      :confidence => 2,
      :relative_path => "engines/user_removal/app/models/account.rb"
  end

  def test_mass_assignment_13
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "c505002e3567c74c8197586751d0cf9ab245aee0068f05c93589959b14dc40c8",
      :warning_type => "Mass Assignment",
      #noline,
      :message => "Potentially dangerous attribute available for mass assignment: :banned",
      :confidence => 1,
      :relative_path => "engines/user_removal/app/models/account.rb"
  end

  def test_mass_assignment_14
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "962a14c66f5f83ece9a22700939111a0b71ed2c925980416f1b664a601e87070",
      :warning_type => "Mass Assignment",
      #noline,
      :message => "Potentially dangerous attribute available for mass assignment: :account_id",
      :confidence => 0,
      :relative_path => "engines/user_removal/app/models/user.rb"
  end

  def test_mass_assignment_15
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "fa154c3e50c02c70f4351dd6731085657dfb0b9ed73ee223ad5444b31bc1d31f",
      :warning_type => "Mass Assignment",
      #noline,
      :message => "Potentially dangerous attribute available for mass assignment: :admin",
      :confidence => 0,
      :relative_path => "engines/user_removal/app/models/user.rb"
  end

  def test_mass_assignment_16
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "98c24601f549d41e0d0367e8bcefc6083263fa175a2978ace0340c6446e57603",
      :warning_type => "Mass Assignment",
      #noline,
      :message => "Potentially dangerous attribute available for mass assignment: :status_id",
      :confidence => 2,
      :relative_path => "engines/user_removal/app/models/user.rb"
  end

  def test_csrf_without_exception
    assert_warning :type => :controller,
      :warning_code => 86,
      :fingerprint => "4d109bd02e4ccb3ea4c51485c947be435ee006a61af7d2cd37d1b358c7469189",
      :warning_type => "Cross-Site Request Forgery",
      :message => "`protect_from_forgery` should be configured with `with: :exception`",
      :confidence => 1,
      :relative_path => "app/controllers/application_controller.rb"
  end

  def test_csrf_in_engine
    assert_warning :type => :controller,
      :warning_code => 7,
      :fingerprint => "bdd5f4f1cdd2e9fb24adc4e9333f2b2eb1d0325badcab7c0b89c25952a2454e8",
      :warning_type => "Cross-Site Request Forgery",
      :line => 1,
      :message => /^`protect_from_forgery`\ should\ be\ called\ /,
      :confidence => 0,
      :relative_path => "engines/user_removal/app/controllers/base_controller.rb",
      :user_input => nil
  end

  def test_xml_dos_CVE_2015_3227
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "ea8edcadc48c04a69e0bee3bdb214ce61f7837b46e9c254b61993660653d1ec6",
      :warning_type => "Denial of Service",
      :line => 4,
      :message => /^Rails\ 4\.0\.0\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
      :relative_path => "gems.rb",
      :user_input => nil
  end

  def test_denial_of_service_CVE_2016_0751
    assert_warning :type => :warning,
      :warning_code => 94,
      :fingerprint => "13138593b5d3af97b9b674220c811229870f418c36717cb3c3df69928264bc95",
      :warning_type => "Denial of Service",
      :line => 4,
      :message => /^Rails\ 4\.0\.0\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
      :relative_path => "gems.rb",
      :user_input => nil
  end

  def test_nested_attributes_bypass_workaround_CVE_2015_7577
    assert_no_warning :type => :model,
      :warning_code => 95,
      :fingerprint => "2b1b6ac6e2348889ac0e1a7fdf0861dba7af91d794c454f8b4b07e7655a19610",
      :warning_type => "Nested Attributes",
      :line => 4,
      :message => /^Rails\ 4\.0\.0\ does\ not\ call\ `:reject_if`\ opt/,
      :confidence => 1,
      :relative_path => "engines/user_removal/app/models/user.rb",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2016_6316
    assert_warning :type => :warning,
      :warning_code => 102,
      :fingerprint => "88b10c71ffa09afd9ec3dec09e08647caceb9977e23c80abc0de6bf024bb85b9",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.0\.0\ `content_tag`\ does\ not\ escape\ /,
      :confidence => 1,
      :relative_path => "gems.rb",
      :user_input => nil
  end

  def test_unmaintained_dependency_rails
    assert_warning check_name: "EOLRails",
      type: :warning,
      warning_code: 120,
      fingerprint: "918071d2713bdcc73e9cd9b5a1a3a59edf41d95fff50ab8c21f76f692fb5e0d7",
      warning_type: "Unmaintained Dependency",
      line: 4,
      message: /^Support\ for\ Rails\ 4\.0\.0\ ended\ on\ 2017\-04/,
      confidence: 0,
      relative_path: "gems.rb",
      code: nil,
      user_input: nil
  end
end
