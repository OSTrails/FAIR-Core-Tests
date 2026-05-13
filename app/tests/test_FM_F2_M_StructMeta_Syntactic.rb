class FAIRTest
  def self.test_FM_F2_M_StructMeta_Syntactic_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Structured Metadata',
      testid: 'test_FM_F2_M_StructMeta_Syntactic',
      description: 'Tests whether a machine is able to find structured metadata.
      This could be (for example) XML, RDFa, embedded json,
      json-ld, or content-negotiated structured metadata such as RDF Turtle.  This test does not require that the
      metadata be linked data, but it does require that the metadata be structured in a way that a machine can parse it.
      Discovered metadata terms are not evaluated',
      metric: 'https://w3id.org/fair-metrics/general/FM_F2_M_StructMeta',
      indicators: 'https://doi.org/10.25504/FAIRsharing.e05e98',
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

  def self.test_FM_F2_M_StructMeta_Syntactic(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_F2_M_StructMeta_Syntactic_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_F2_M_StructMeta_Syntactic_meta[:testversion]}'\n"

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
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    if hash.any?
      output.score = 'pass'
      output.comments << "SUCCESS: Found structured metadata.\n"
    elsif graph.size > 0 # have we found anything yet?
      output.score = 'pass'
      output.comments << "SUCCESS: Found linked data (this may or may not have originated from the author).\n"
    else
      output.score = 'fail'
      output.comments << "FAILURE: unable to find any kind of structured metadata.\n"
    end

    output.createEvaluationResponse
  end

  def self.test_FM_F2_M_StructMeta_Syntactic_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_F2_M_StructMeta_Syntactic_meta)
    api.get_api
  end

  def self.test_FM_F2_M_StructMeta_Syntactic_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_F2_M_StructMeta_Syntactic_meta)
    dcat.get_dcat
  end
end
