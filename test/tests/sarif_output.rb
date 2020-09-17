require_relative '../test'
require 'json'

class SARIFOutputTests < Minitest::Test
  def setup
    @@sarif ||= JSON.parse(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_sarif)
  end

  def test_log_shape
    assert_equal '2.1.0', @@sarif['version']
    assert_equal 'https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.5.json', @@sarif['$schema']
  end

  def test_runs_shape
    # Log includes runs, an array, of length 1
    assert runs = @@sarif['runs']
    assert_equal 1, runs.length

    # The single run contains tool, and results
    assert_equal runs[0].keys, ['tool', 'results']

    # The single run contains a single tool
    assert_equal 1, runs[0]['tool'].length
  end

  def test_driver_shape
    # Tool includes a driver
    assert driver = @@sarif.dig('runs', 0, 'tool', 'driver')

    # Driver has a name, informationUri, semanticVersion, and rules
    assert_equal driver.keys, ['name', 'informationUri', 'semanticVersion', 'rules']

    # Driver name is 'Brakeman'
    assert_equal driver['name'], 'Brakeman'

    # Driver informationUri is 'https://brakemanscanner.org'
    assert_equal driver['informationUri'], 'https://brakemanscanner.org'

    # Driver semanticVersion is Brakeman::Version
    assert_equal driver['semanticVersion'], Brakeman::Version
  end

  def test_rules_shape
    assert rules = @@sarif.dig('runs', 0, 'tool', 'driver', 'rules')
    rules.each do |rule|
      # Each rule id starts with BRAKE
      assert rule['id'].start_with? 'BRAKE'

      # Each rule has a name, ...
      assert rule['name']

      # ... fullDescription, ...
      assert rule['fullDescription']['text']

      # ... helpUri, ...
      assert rule['helpUri']

      # ... help, ...
      assert rule['help']['text']
      assert rule['help']['markdown']

      # ... and a property bag containing tags
      assert rule['properties']['tags']
    end

    # Each rule id is unique
    assert_equal rules.length, rules.map{ |rule| rule['id'] }.uniq.length
  end

  def test_results_shape
    assert results = @@sarif.dig('runs', 0, 'results')
    results.each do |result|
      # Each result has message, ...
      assert result['message']['text']

      # ... ruleId, ...
      assert result['ruleId']

      # ... ruleIndex, ...
      assert result['ruleIndex']

      # ... level, ...
      assert ['error', 'warning', 'note'].include? result['level']

      # (and ruleIndex maps correctly onto the corresponding rule), ...
      assert_equal result['ruleId'], @@sarif.dig('runs', 0, 'tool', 'driver', 'rules', result['ruleIndex'], 'id')

      # ... locations, ...
      assert locations = result['locations']
      locations.each do |location|
        # Each location has a physical location, ...
        assert location['physicalLocation']

        # Each location has a region
        assert location['physicalLocation']['region']['startLine']
      end
    end
  end
end
