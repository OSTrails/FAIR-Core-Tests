class FAIRTest
  def self.test_FM_I3_M_QualRef_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Metadata Contains Outward Links',
      testid: 'test_FM_I3_M_QualRef',
      description: 'Maturity Indicator to test if the metadata links outward to third-party resources.
      Note that this test only examines metadata that is represented as Linked Data.
      The test passes if the object of any triple (non-structural triples only) is a URI that points to a host
      other than the host of the metadata itself.  This is a very weak test,
      but it is designed to encourage data stewards to link their metadata to external resources. ',
      metric: 'https://w3id.org/fair-metrics/general/FM_I3_M_QualRef',
      indicators: 'https://doi.org/10.25504/FAIRsharing.ae22b8',
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

  def self.test_FM_I3_M_QualRef(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_I3_M_QualRef_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_I3_M_QualRef_meta[:testversion]}'\n"

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
    g = graph

    if g.size > 0 # have we found anything yet?
      output.comments << "INFO: Linked data was found.\n"
    else
      output.comments << "FAILURE: No linked data was found.  Test is exiting.\n"
      output.score = 'fail'
      return output.createEvaluationResponse
    end

    success = 0
    count = 0
    hosts = []
    metadata.finalURI.each do |uri|
      next unless uri =~ /^http/

      this = URI(uri.to_s)
      hosts << this.host # get only the host poart of the URI
    end
    g.each do |stm|
      predicate = stm.predicate
      next if predicate.to_s =~ %r{1999/xhtml} # ignore XHTML structural triples like buttons

      object = stm.object
      next unless object.resource? && !object.anonymous?

      thisuri = URI(object.value)
      output.comments << "INFO: Testing #{thisuri}.\n"
      success += 1 unless hosts.include?(thisuri.host) # NOTE: that we're checking for outward links
      count += 1
    end

    if success >= 1 # this is a very weak test!
      output.comments << "SUCCESS: #{success} of the #{count} triples discovered in the linked metadata pointed to resources hosted elsewhere.  "
      output.score = 'pass'
    else
      output.comments << "FAILURE: #{success} of the #{count} triples discovered in the linked metadata pointed to resources hosted elsewhere.  The minimum to pass this test is 1.  "
      output.score = 'fail'
    end

    output.createEvaluationResponse
  end

  def self.test_FM_I3_M_QualRef_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_I3_M_QualRef_meta)
    api.get_api
  end

  def self.test_FM_I3_M_QualRef_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_I3_M_QualRef_meta)
    dcat.get_dcat
  end
end
