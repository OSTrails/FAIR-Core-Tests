class FAIRTest
  def self.test_FM_F1_M_IdentPersistent_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Identifier Persistence',
      testid: 'test_FM_F1_M_IdentPersistent',
      description: "Metric to test if the unique identifier of the metadata resource
      is likely to be persistent. Known schema are registered in
      FAIRSharing (https://fairsharing.org/standards/?q=&selected_facets=type_exact:identifier%20schema).
      For URLs that don't follow a schema in FAIRSharing we test
      known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark).",
      metric: 'https://w3id.org/fair-metrics/general/FM_F1_M_IdentPersistent',
      indicators: 'https://doi.org/10.25504/FAIRsharing.e226cb',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'FAIR Principles'],
      themes: ['http://edamontology.org/topic_4012'],
      organization: 'OSTrails Project',
      org_url: 'https://ostrails.eu/',
      responsible_developer: 'Mark D Wilkinson',
      email: 'mark.wilkinson@upm.es',
      response_description: 'The response is "pass", "fail" or "indeterminate"',
      schemas: { 'resource_identifier' => ['string', 'the GUID being tested'] },
      organizations: [{ 'name' => 'OSTrails Project', 'url' => 'https://ostrails.eu/' }],
      individuals: [{ 'name' => 'Mark D Wilkinson', 'email' => 'mark.wilkinson@upm.es' }],
      creator: 'https://orcid.org/0000-0001-6960-357X',
      protocol: ENV.fetch('TEST_PROTOCOL', 'https'),
      host: ENV.fetch('TEST_HOST', 'localhost'),
      basePath: ENV.fetch('TEST_PATH', '/tests')
    }
  end

  def self.test_FM_F1_M_IdentPersistent(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_F1_M_IdentPersistent_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_F1_M_IdentPersistent_meta[:testversion]}'\n"

    type = FAIRChampionHarvester::Core.typeit(guid)

    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    if !type
      output.comments << "INDETERMINATE: The GUID identifier of the metadata #{guid} did not match any known identification system.\n"
      output.score = 'indeterminate'
    elsif type == 'uri'
      output.comments << "INFO: The metadata GUID appears to be a URL.  Testing known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark, doi(as URL)).\n"
      if (guid =~ /(purl)\./) or (guid =~ /(oclc)\./) or (guid =~ /(fdlp)\./) or (guid =~ /(purlz)\./) or (guid =~ /(w3id)\./) or (guid =~ /(ark):/) or (guid =~ /(doi.org)/)
        output.comments << "SUCCESS: The metadata GUID conforms with #{::Regexp.last_match(1)}, which is known to be persistent.\n"
        output.score = 'pass'
      else
        output.comments << "INDETERMINATE: The metadata GUID does not conform with any known permanent-URL system.\n"
        output.score = 'indeterminate'
      end
    else
      output.comments << "SUCCESS: The GUID of the metadata is a #{type}, which is known to be persistent.\n"
      output.score = 'pass'
    end
    output.createEvaluationResponse
  end

  def self.test_FM_F1_M_IdentPersistent_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_F1_M_IdentPersistent_meta)
    api.get_api
  end

  def self.test_FM_F1_M_IdentPersistent_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_F1_M_IdentPersistent_meta)
    dcat.get_dcat
  end
end
