class FAIRTest
  def self.test_FM_I1_M_FormLangSemantic_Data_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Data record is represented as Linked Data',
      testid: 'test_FM_I1_M_FormLangSemantic_Data',
      description: "Test if the Data record referred to by the metadata uses an RDF syntax in which terms are
      semantically-grounded in ontologies.  Any syntax of ontologically-grounded linked data will pass
      this test. ",
      metric: 'https://w3id.org/fair-metrics/general/FM_I1_M_FormLangSemantic',

      indicators: 'https://doi.org/10.25504/FAIRsharing.ec5648',
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

  def self.test_FM_I1_M_FormLangSemantic_Data(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_I1_M_FormLangSemantic_Data_meta
    )
    output.comments << "INFO: TEST VERSION '#{test_FM_I1_M_FormLangSemantic_Data_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    graph = metadata.graph
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    output.score = 'fail' # default to fail, and then we will change to pass if we find something

    output.comments << "INFO: Searching for linked data metadata.\n"

    if graph.size.positive? # have we found anything yet?
      output.comments << "SUCCESS: linked data style metadata found\n"
      output.score = 'pass'
    end
    output.comments << "FAILURE: No metadata found in linked data style.\n" if output.score == 'fail'
    output.createEvaluationResponse
  end

  def self.test_FM_I1_M_FormLangSemantic_Data_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_I1_M_FormLangSemantic_Data_meta)
    api.get_api
  end

  def self.test_FM_I1_M_FormLangSemantic_Data_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_I1_M_FormLangSemantic_Data_meta)
    dcat.get_dcat
  end
end
