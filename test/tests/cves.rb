require_relative '../test'
require 'brakeman/rescanner'

class CVETests < Minitest::Test
  include BrakemanTester::RescanTestHelper
  include BrakemanTester::FindWarning

  def report
    @rescanner.tracker.report.to_hash
  end

  def assert_version version, gem = :rails
    if gem == :rails
      assert_equal version, @rescanner.tracker.config.rails_version
    else
      assert_equal version, @rescanner.tracker.config.gem_version(gem)
    end
  end

  def test_CVE_2015_3226_4_1_1
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.1.1"
    end

    assert_version "4.1.1"
    assert_warning :type => :warning,
      :warning_code => 87,
      :fingerprint => "6c2281400c467a0100bcedeb122bc2cb024d09e538e18f4c7328c3569fff6754",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.1\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3226_4_2_1
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.2.1"
    end

    assert_version "4.2.1"
    assert_warning :type => :warning,
      :warning_code => 87,
      :fingerprint => "6c2281400c467a0100bcedeb122bc2cb024d09e538e18f4c7328c3569fff6754",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3226_workaround
    initializer = "config/initializers/json.rb"
    before_rescan_of ["Gemfile", initializer], "rails4" do
      replace "Gemfile", "4.0.0", "4.2.1"

      write_file initializer, <<-RUBY
      module ActiveSupport
        module JSON
          module Encoding
            private
            class EscapedString
              def to_s
                self
              end
            end
          end
        end
      end
      RUBY
    end

    assert_version "4.2.1"
    assert_no_warning :type => :warning,
      :warning_code => 87,
      :fingerprint => "6c2281400c467a0100bcedeb122bc2cb024d09e538e18f4c7328c3569fff6754",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_4_2_1
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.2.1"
    end

    assert_version "4.2.1"
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "6ad4464dbb2a999591c7be8346dc137c3372b280f4a8b0c024fef91dfebeeb83",
      :warning_type => "Denial of Service",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_4_1_11
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.1.11"
    end

    assert_version "4.1.11"
    assert_no_warning :type => :warning,
      :warning_code => 88,
      :warning_type => "Denial of Service",
      :line => 4,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_workaround
    initializer = "config/initializers/xml.rb"
    before_rescan_of ["Gemfile", initializer], "rails4" do
      replace "Gemfile", "4.0.0", "4.1.11"
      write_file initializer, "ActiveSupport::XmlMini.backend = 'Nokogiri'"
    end

    assert_version "4.1.11"
    assert_no_warning :type => :warning,
      :warning_code => 88,
      :warning_type => "Denial of Service",
      :line => 4,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_3_2_22
    before_rescan_of "Gemfile.lock", "rails3.2" do
      replace "Gemfile.lock", "rails (3.2.9.rc2)", "rails (3.2.22)"
    end

    assert_version "3.2.22"
    assert_no_warning :type => :warning,
      :warning_code => 88,
      :warning_type => "Denial of Service"
  end

  def test_railties_version
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "rails", "railties"
    end

    assert_version "4.0.0"
  end

  def test_new_bundler_file_names
    before_rescan_of ["Gemfile", "Gemfile.lock"] do
      rename "Gemfile", "gems.rb"
      rename "Gemfile.lock", "gems.locked"
    end

    skip "This test was always wrong?"

    assert_version "3.2.9.rc2"
    assert_new 0
    assert_fixed 0
  end

  def test_ignored_secrets_yml
    before_rescan_of [".gitignore", "config/secrets.yml"], "rails4" do
      append ".gitignore", "\nconfig/secrets.yml"
    end

    assert_new 0
    assert_fixed 1
  end

  def test_CVE_2015_7576
    before_rescan_of "Gemfile.lock", "rails3.1" do
      replace "Gemfile.lock", " rails (3.1.0)", " rails (3.2.22.1)"
    end

    assert_version "3.2.22.1"
    assert_new 0
    assert_no_warning type: :controller, :warning_code => 93
  end

  def test_CVE_2016_0751
    before_rescan_of "Gemfile.lock", "rails3.1" do
      replace "Gemfile.lock", " rails (3.1.0)", " rails (3.2.22.1)"
    end

    assert_new 0
    assert_version "3.2.22.1"
    assert_no_warning type: :controller, :warning_code => 94
  end

  def test_CVE_2015_7577
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "rails', '4.0.0'", "rails', '4.2.5.1'"
    end

    assert_version "4.2.5.1"
    assert_no_warning type: :model, :warning_code => 95
    assert_warning :warning_code => 102 # CVE-2016-6317
    assert_new 3 # RCE to Dynamic renders and CVE-2016-6317, unrelated
  end

  def test_sanitize_cves
    before_rescan_of "Gemfile.lock", "rails5" do
      replace "Gemfile.lock", "rails-html-sanitizer (1.0.2)", "rails-html-sanitizer (1.0.3)"
    end

    assert_version "1.0.3", :'rails-html-sanitizer'

    assert_new 2 # XSS goes from high to weak
    assert_fixed 5
    assert_no_warning :warning_code => 96
    assert_no_warning :warning_code => 97
    assert_no_warning :warning_code => 98
  end

  def test_CVE_2015_7581
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "rails', '4.0.0'", "rails', '4.2.5.1'"
    end

    assert_new 3 # RCE to Dynamic renders and CVE-2016-6317, unrelated
    assert_version "4.2.5.1"
    assert_no_warning :warning_code => 100
    assert_warning :warning_code => 102 # CVE-2016-6317
  end

  def test_CVE_2016_6316_rails3
    before_rescan_of ["Gemfile.lock", "app/views/home/test_content_tag.html.erb"], "rails3" do
      replace "Gemfile.lock", "rails (3.0.3)", "rails (3.2.22.4)"
    end

    assert_version "3.2.22.4"
    expected = if RUBY_PLATFORM == "java"
                 31 # 1 for CVE_2013_1856
               else
                 30
               end
    assert_fixed expected # 3 for CVE-2016-6316
  end

  def test_CVE_2016_6316_rails5
    before_rescan_of ["Gemfile.lock", "app/views/widget/content_tag.html.erb"], "rails5" do
      replace "Gemfile.lock", "rails (5.0.0)", "rails (5.0.0.1)"
    end

    assert_version "5.0.0.1"
    assert_fixed 3 # 3 for CVE-2016-6316
  end

  def test_CVE_2018_3760_sprockets
    # Have to include `.ruby-version` otherwise it changes the EOL Ruby warning
    # because the warning will point at Gemfile.lock instead of .ruby-version
    before_rescan_of [".ruby-version", "Gemfile.lock", "config/environments/production.rb"], "rails5.2" do
      replace "Gemfile.lock", "sprockets (3.7.1)", "sprockets (4.0.0.beta2)"
      replace "config/environments/production.rb", "config.assets.compile = false", "config.assets.compile = true"
    end

    assert_version "4.0.0.beta2", :sprockets
    assert_new 1 # CVE-2018-3760
  end

  def test_CVE_2018_8048_exact_fix_version
    before_rescan_of [".ruby-version", "Gemfile.lock"], "rails5.2" do
      replace "Gemfile.lock", "loofah (2.1.1)", "loofah (2.2.1)"
    end

    assert_version "2.2.1", :loofah
    assert_fixed 1
  end

  def test_CVE_2018_8048_newer_version
    before_rescan_of [".ruby-version", "Gemfile.lock"], "rails5.2" do
      replace "Gemfile.lock", "loofah (2.1.1)", "loofah (2.10.1)"
    end

    assert_version "2.10.1", :loofah
    assert_fixed 1
  end

  def test_CVE_2013_0276
    before_rescan_of "app/models/protected.rb", "rails2", :collapse_mass_assignment => true do
      replace "app/models/protected.rb", "attr_accessible nil", "attr_protected :admin"
    end

    warning = new.find do |w|
      w.warning_code == 51 # CVE-2013-0276
    end

    refute_nil warning
  end

  def test_CVE_2010_3933_rails3
    before_rescan_of ["Gemfile.lock", "app/models/a.rb"], "rails3", :run_checks => ["CheckNestedAttributes"] do
      replace "Gemfile.lock", "rails (3.0.3)", "rails (3.0.0)"
      write_file "app/models/a.rb", <<-RUBY
      class A < ActiveRecord::Base
        accepts_nested_attributes_for :b
      end
      RUBY
    end

    assert_version "3.0.0"

    warning = new.find do |w|
      w.warning_code == 31 and # CVE_2010_3933
        w.message.to_s == "Vulnerability in nested attributes (CVE-2010-3933). Upgrade to Rails 3.0.1"
    end

    refute_nil warning
  end

  def test_CVE_2020_8159_rails5_upgrade
    before_rescan_of "Gemfile", "rails5", run_checks: ["CheckPageCachingCVE"] do
      replace "Gemfile",
        "gem 'actionpack-page_caching', '1.2.0'",
        "gem 'actionpack-page_caching', '1.2.2'"
    end

    assert fixed.find { |w|
      w.warning_code == Brakeman::WarningCodes.code(:CVE_2020_8159)
    }

    assert_fixed 1 # CVE-2020-8159
    assert_new 0
  end

  def test_CVE_2020_8159_rails5_caches_page
    before_rescan_of "app/controllers/test_cve_2020_8519.rb", "rails5", run_checks: ["CheckPageCachingCVE"] do
      write_file "app/controllers/test_cve_2020_8519.rb", <<-RUBY
      class TestCVEController < ApplicationController
        caches_page :stuff
      end
      RUBY
    end

    warning = new.find do |w|
      w.warning_code == Brakeman::WarningCodes.code(:CVE_2020_8159)
    end

    refute_nil warning

    # Warning should be :high now
    assert_equal 0, warning.confidence
    assert_fixed 1
    assert_new 1
  end

  def test_CVE_2020_8166
    Date.stub :today, Date.parse('2021-04-05') do
      before_rescan_of [".ruby-version", "Gemfile.lock"], "rails5.2" do
        replace "Gemfile.lock", " rails (5.2.0.beta2)", " rails (5.2.4.3)"
      end
    end

    assert_new 0
    assert_version "5.2.4.3"
    assert_no_warning type: :generic, :warning_code => 116
  end

  def test_CVE_2020_8166_rails6
    Date.stub :today, Date.parse('2022-04-06') do
      before_rescan_of "Gemfile", "rails6" do
        replace "Gemfile", "gem 'rails', '~> 6.0.0.beta2'", "gem 'rails', '~> 6.0.0'"
      end
    end

    assert_new 1
    assert_version "6.0.0"
    assert_warning type: :generic, :warning_code => 116
  end

  def test_old_sanitize_cves
    before_rescan_of "app/views/users/one.html.haml", "rails5.2" do
      replace "app/views/users/one.html.haml", "sanitize", "not_sanitize"
      replace "app/views/users/one.html.haml", "sanitize", "not_sanitize"
    end

    # Confidence is high when uses of `sanitize` are found.
    # This tests that the confidence is lowered to medium
    # when uses of `sanitize` are removed.
    assert_warning warning_code: 107, confidence: 1
    assert_warning warning_code: 106, confidence: 1
  end

  def test_CVE_2022_32209_rails6
    before_rescan_of "Gemfile", "rails6" do
      append "Gemfile", "\ngem 'rails-html-sanitizer', '1.4.2'"
    end

    assert_new 1
    assert_version '1.4.2', :'rails-html-sanitizer'
    assert_warning type: :generic, :warning_code => 124
  end

  def test_CVE_2022_32209_fix_version
    before_rescan_of "Gemfile", "rails6" do
      append "Gemfile", "\ngem 'rails-html-sanitizer', '1.4.3'"
    end

    assert_new 0
    assert_version '1.4.3', :'rails-html-sanitizer'
    assert_no_warning type: :generic, :warning_code => 124
  end
end
