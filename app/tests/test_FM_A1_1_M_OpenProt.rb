class FAIRTest
  def self.test_FM_A1_1_M_OpenProt_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Uses open free protocol for metadata retrieval',
      testid: 'test_FM_A1_1_M_OpenProt',
      description: 'Metadata may be retrieved by an open and free protocol.  Tests metadata GUID for its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.',
      metric: 'https://w3id.org/fair-metrics/general/FM_A1-1_M_OpenProt',
      indicators: 'https://doi.org/10.25504/FAIRsharing.7612c1',
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

  def self.test_FM_A1_1_M_OpenProt(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_A1_1_M_OpenProt_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_A1_1_M_OpenProt_meta[:testversion]}'\n"

    type = FAIRChampionHarvester::Core.typeit(guid) # this is where the magic happens!

    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    if type
      output.score = 'pass'
      output.comments << "SUCCESS: The identifier #{guid} is of type #{type}, which is resolvable by an open protocol."
      output.createEvaluationResponse
    else
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      output.createEvaluationResponse
    end
  end

  def self.test_FM_A1_1_M_OpenProt_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_A1_1_M_OpenProt_meta)
    api.get_api
  end

  def self.test_FM_A1_1_M_OpenProt_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_A1_1_M_OpenProt_meta)
    dcat.get_dcat
  end
end
