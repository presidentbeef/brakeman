require_relative '../test'
require 'json'

class SARIFOutputTests < Minitest::Test

  def tracker_3_2
    @@tracker_3_2 ||= Brakeman.run("#{TEST_PATH}/apps/rails3.2") # has no brakeman.ignore
  end

  def setup
    @@sarif ||= JSON.parse(tracker_3_2.report.to_sarif)
    @@sarif_with_ignore ||= JSON.parse(Brakeman.run(File.join(TEST_PATH, 'apps', 'rails4')).report.to_sarif) # has ignored warnings
  end

  def test_render_message
    report = Brakeman::Report::SARIF.new tracker_3_2
    assert_nil report.render_message(nil)
    assert_equal 'Very serious sentence.', report.render_message('Very serious sentence')
    assert_equal 'Nothing to see here.', report.render_message('Nothing to see here.')
  end

  def test_log_shape
    assert_equal '2.1.0', @@sarif['version']
    assert_equal 'https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json', @@sarif['$schema']
  end

  def test_runs_shape
    # Log includes runs, an array, of length 1
    assert runs = @@sarif['runs']
    assert_equal 1, runs.length

    # The single run contains some data
    assert_equal ['tool', 'results', 'originalUriBaseIds'], runs[0].keys

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

        # Each physical location has an artifact location, ...
        assert location['physicalLocation']['artifactLocation']

        # Each artifact location has a relative URI
        assert location['physicalLocation']['artifactLocation']['uri']
        refute location['physicalLocation']['artifactLocation']['uri'].start_with? 'file://'


        # and a uriBaseId
        assert_equal '%SRCROOT%', location['physicalLocation']['artifactLocation']['uriBaseId']

        # Each location has a region
        assert location['physicalLocation']['region']['startLine']
      end
    end
  end

  def test_with_ignore_has_one_suppressed_finding
    assert_equal(
      1,
      @@sarif_with_ignore.dig('runs', 0, 'results').
        select { |f| f['suppressions'] }.count
    )
  end

  def test_with_ignore_results_suppression_shape
    @@sarif_with_ignore.dig('runs', 0, 'results').each do |finding|
      suppressions = finding['suppressions']
      next unless suppressions

      # Each finding with suppressions has exactly one...
      assert_equal 1, suppressions.count
      assert suppression = suppressions[0]

      # ...external suppression...
      assert_equal 'external', suppression['kind']

      # ...with a valid physical location...
      assert suppression['location']['physicalLocation']['artifactLocation']['uri']
      assert_equal '%SRCROOT%', suppression['location']['physicalLocation']['artifactLocation']['uriBaseId']

      # ...and a justification (will be nil if no notes is set).
      assert suppression['justification']
    end
  end

  def test_uri_base_ids_with_absolute_app_path
    assert base_uris = @@sarif.dig('runs', 0, 'originalUriBaseIds')
    assert_equal ['%SRCROOT%'], base_uris.keys

    # Only %SRCROOT% with no URI
    assert base_uris['%SRCROOT%']
    assert_equal ['description'], base_uris['%SRCROOT%'].keys
  end

  def test_uri_base_ids_with_relative_app_path
    original_app_path = tracker_3_2.options[:app_path] # Horrible hack
    tracker_3_2.options[:app_path] = 'something/relative'
    sarif = JSON.parse(tracker_3_2.report.to_sarif)

    assert base_uris = sarif.dig('runs', 0, 'originalUriBaseIds')
    assert_equal ['PROJECTROOT', '%SRCROOT%'], base_uris.keys

    # %SRCROOT% should have the relative path and point to PROJECTROOT
    # as its base
    assert base_uris['%SRCROOT%']
    assert_equal ['uri', 'uriBaseId', 'description'], base_uris['%SRCROOT%'].keys
    assert_equal 'something/relative/', base_uris['%SRCROOT%']['uri']
    assert_equal 'PROJECTROOT', base_uris['%SRCROOT%']['uriBaseId']

    # PROJECTROOT should not have a URI
    assert base_uris['PROJECTROOT']
    assert_equal ['description'], base_uris['PROJECTROOT'].keys
  ensure
    tracker_3_2.options[:app_path] = original_app_path
  end

  def test_uri_base_ids_with_absolute_app_path_and_absolute_path_option
    tracker_3_2.options[:absolute_paths] = true
    sarif = JSON.parse(tracker_3_2.report.to_sarif)

    assert base_uris = sarif.dig('runs', 0, 'originalUriBaseIds')
    assert_equal ['%SRCROOT%'], base_uris.keys

    # Only %SRCROOT% with absolute URI
    assert base_uris['%SRCROOT%']
    assert_equal ['uri','description'], base_uris['%SRCROOT%'].keys
    assert base_uris['%SRCROOT%']['uri'].start_with? 'file://'
    assert base_uris['%SRCROOT%']['uri'].end_with? '/'
  ensure
    tracker_3_2.options[:absolute_paths] = false
  end

  def test_uri_base_ids_with_relative_app_path_and_absolute_path_option
    original_app_path = tracker_3_2.options[:app_path] # Horrible hack
    tracker_3_2.options[:app_path] = 'something/relative'
    tracker_3_2.options[:absolute_paths] = true
    sarif = JSON.parse(tracker_3_2.report.to_sarif)

    assert base_uris = sarif.dig('runs', 0, 'originalUriBaseIds')
    assert_equal ['PROJECTROOT', '%SRCROOT%'], base_uris.keys

    # %SRCROOT% should have the relative path and point to PROJECTROOT
    # as its base
    assert base_uris['%SRCROOT%']
    assert_equal ['uri', 'uriBaseId', 'description'], base_uris['%SRCROOT%'].keys
    assert_equal 'something/relative/', base_uris['%SRCROOT%']['uri']
    assert_equal 'PROJECTROOT', base_uris['%SRCROOT%']['uriBaseId']

    # PROJECTROOT should have an absolute URI
    assert base_uris['PROJECTROOT']
    assert_equal ['uri', 'description'], base_uris['PROJECTROOT'].keys
    assert base_uris['PROJECTROOT']['uri'].start_with? 'file://'
    assert base_uris['PROJECTROOT']['uri'].end_with? '/'
  ensure
    tracker_3_2.options[:app_path] = original_app_path
    tracker_3_2.options[:absolute_paths] = false
  end

  def test_uri_base_ids_with_default_app_path_and_absolute_path_option
    original_app_path = tracker_3_2.options[:app_path] # Horrible hack
    tracker_3_2.options[:app_path] = '.'
    tracker_3_2.options[:absolute_paths] = true
    sarif = JSON.parse(tracker_3_2.report.to_sarif)

    assert base_uris = sarif.dig('runs', 0, 'originalUriBaseIds')
    assert_equal ['%SRCROOT%'], base_uris.keys

    # Only %SRCROOT% with absolute URI
    assert base_uris['%SRCROOT%']
    assert_equal ['uri', 'description'], base_uris['%SRCROOT%'].keys
    assert base_uris['%SRCROOT%']['uri'].start_with? 'file://'
    assert base_uris['%SRCROOT%']['uri'].end_with? '/'
  ensure
    tracker_3_2.options[:app_path] = original_app_path
    tracker_3_2.options[:absolute_paths] = false
  end
end
