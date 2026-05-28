class FAIRTest
  def self.test_FM_I1_M_FormalLangSyntax_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Data Knowlege Representation Language (Weak Test)',
      testid: 'test_FM_I1_M_FormalLangSyntax',
      description: "Test if the data uses a formal language broadly applicable for knowledge
      representation.  This particular test takes a broad view of what defines a
      'knowledge representation language'; in this evaluation, a
      knowledge representation language is interpreted any form of structured data (i.e. a purely syntactic test).  This test is a 'weak' test because it does not attempt to evaluate the semantics of the data, but only the syntax.  The presence of structured data in any form is sufficient to pass this test.",
      metric: 'https://w3id.org/fair-metrics/general/FM_I1_M_FormLangSyntax',
      indicators: 'https://doi.org/10.25504/FAIRsharing.ec5648',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'Syntax', 'structured data', 'FAIR Principles'],
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

  def self.test_FM_I1_M_FormalLangSyntax(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_I1_M_FormalLangSyntax_meta
    )
    output.comments << "INFO: TEST VERSION '#{test_FM_I1_M_FormalLangSyntax_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    hash = metadata.hash
    graph = metadata.graph
    properties = FAIRChampionHarvester::Core.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    output.score = 'fail' # default to fail, and then we will change to pass if we find something
    output.comments << "INFO: Searching for hash-style metadata.\n"
    properties.each do |keyval|
      (key, value) = keyval
      key = key.to_s
      value = value.to_s
      if key && value
        output.comments << "SUCCESS: hash style metadata found.\n"
        output.score = 'pass'
      end
    end
    output.comments << "INFO: Searching for linked data metadata.\n"

    if graph.size > 0 # have we found anything yet?
      output.comments << "SUCCESS: linked data style metadata found\n"
      output.score = 'pass'
    end
    output.comments << "FAILURE: No metadata found in either hash or linked data style.\n" if output.score == 'fail'
    output.createEvaluationResponse
  end

  def self.test_FM_I1_M_FormalLangSyntax_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_I1_M_FormalLangSyntax_meta)
    api.get_api
  end

  def self.test_FM_I1_M_FormalLangSyntax_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_I1_M_FormalLangSyntax_meta)
    dcat.get_dcat
  end
end
