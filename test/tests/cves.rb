require 'brakeman/rescanner'

class CVETests < Test::Unit::TestCase
  include BrakemanTester::RescanTestHelper
  include BrakemanTester::FindWarning

  def report
    @rescanner.tracker.report.to_hash
  end

  def assert_version version, gem = :rails
    if gem == :rails
      assert_equal version, @rescanner.tracker.config[:rails_version]
    else
      assert_equal version, @rescanner.tracker.config[:gems][gem][:version]
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
      :warning_type => "Cross Site Scripting",
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
      :warning_type => "Cross Site Scripting",
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
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil 
  end

end
