class FAIRTest
  def self.test_FM_F2_M_StructMeta_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Grounded Metadata',
      testid: 'test_FM_F2_M_StructMeta',
      description: "Tests whether a machine is able to find 'semantically grounded' metadata.
      i.e. metadata terms that are in a resolvable namespace, where resolution
      leads to a definition of the meaning of the term. Examples include JSON-LD,
      embedded schema.org, or any form of RDF. This test excludes XML and other structured metadata formats that do not have resolvable namespaces, even
      even when terms are namespaced.",
      metric: 'https://w3id.org/fair-metrics/general/FM_F2_M_StructMeta',
      indicators: 'https://doi.org/10.25504/FAIRsharing.e05e98',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'structured metadata', 'metadata standards', 'FAIR Principles'],
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

  def self.test_FM_F2_M_StructMeta(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_F2_M_StructMeta_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_F2_M_StructMeta_meta[:testversion]}'\n"

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

    if graph.size > 0 # have we found anything yet?
      output.score = 'pass'
      output.comments << "SUCCESS: found linked-data style structured metadata.\n"
    else
      output.comments << "FAILURE: no linked-data style structured metadata found.\n"
      output.score = 'fail'
    end
    output.createEvaluationResponse
  end

  def self.test_FM_F2_M_StructMeta_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_F2_M_StructMeta_meta)
    api.get_api
  end

  def self.test_FM_F2_M_StructMeta_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_F2_M_StructMeta_meta)
    dcat.get_dcat
  end
end
