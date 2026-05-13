class FAIRTest
  def self.test_FM_F1_M_IdentUnique_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.1',
      testname: 'OSTrails Core: Unique Identifier',
      testid: 'test_FM_F1_M_IdentUnique',
      description: 'Metric to test if the metadata resource has a unique identifier.
      This is done by comparing the GUID to the patterns (by regexp)
      of known GUID schemas such as URLs and DOIs.
      Known schema are registered in FAIRSharing
      (https://fairsharing.org/standards/?q=&selected_facets=type_exact:identifier%20schema)',
      metric: 'https://w3id.org/fair-metrics/general/FM_F1_M_IdentUnique',
      indicators: 'https://doi.org/10.25504/FAIRsharing.b7f1ab',
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

  def self.test_FM_F1_M_IdentUnique(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_F1_M_IdentUnique_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_F1_M_IdentUnique_meta[:testversion]}'\n"

    type = FAIRChampionHarvester::Core.typeit(guid) # this is where the magic happens!

    unless type
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known globally unique identitier system.\n"
      return output.createEvaluationResponse
    end

    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    output.comments << "SUCCESS: Found an identifier of type '#{type}'\n"
    output.score = 'pass'
    output.createEvaluationResponse
  end

  def self.test_FM_F1_M_IdentUnique_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_F1_M_IdentUnique_meta)
    api.get_api
  end

  def self.test_FM_F1_M_IdentUnique_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_F1_M_IdentUnique_meta)
    dcat.get_dcat
  end
end
