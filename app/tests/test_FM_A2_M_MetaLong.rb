class FAIRTest
  def self.test_FM_A2_M_MetaLong_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.1',
      testname: 'OSTrails Core: Metadata Persistence',
      testid: 'test_FM_A2_M_MetaLong',
      description: 'Metric to test if the metadata contains a persistence policy, explicitly identified by a persistencePolicy key (in hashed data) or a http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy predicate in Linked Data.  DOIs are assumed to have metadata persistence.',
      metric: 'https://w3id.org/fair-metrics/general/FM_A2_M_MetaLong',
      indicators: 'https://doi.org/10.25504/FAIRsharing.7c4d7f',
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

  def self.test_FM_A2_M_MetaLong(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_A2_M_MetaLong_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_A2_M_MetaLong_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    hash = metadata.hash
    graph = metadata.graph
    properties = FAIRChampionHarvester::Core.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    g = graph # shorter :-)

    # before we go hunting... if it is a DOI, then it has persistent metadata
    if metadata.guidtype == 'doi'
      output.comments << "PASS: The identifier is a DOI, which is recognized to have persistent metadata.\n"
      output.score = 'pass'
      return output.createEvaluationResponse
    end

    if g.size.positive? # have we found anything yet?
      output.comments << "INFO: Found linked data.  Testing for the 'http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy' predicate.\n"
      query = SPARQL.parse('select ?o where {?s <http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy> ?o}')
      results = query.execute(g)
      if results.any?
        output.comments << "INFO: Found persistence policy predicate with #{results.first[:o]} as its value.  This should be a resolveable URL; Now testing resolution.\n"
        policyuri = results.first[:o].value
        unless policyuri =~ %r{://\w+\.\w+} # the structure of a URI
          output.comments << "FAILURE: http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy states that the range of the property must be a resource.  The discovered value (#{polucyURI}) is not a URL.\n"
          output.score = 'fail'
          return output.createEvaluationResponse
        end

        head, _body = Utils.fetch(policyURI, { 'Accept' => '*/*' }) # returns HTTP object, or false
        if head
          output.comments << "SUCCESS: Persistence policy URL resolved.\n"
          output.score = 'pass'
        else
          output.comments << "FAILURE: Persistence policy did not resolve.\n"
          output.score = 'fail'
        end
        return output.createEvaluationResponse

      else
        output.comments << "WARN: Did not find the #persistencePolicy predicate in the linked data.\n"
      end

    else
      output.comments << "WARN: Could not find any linked data to test for persistence policy references.\n"
    end

    if output.score == 'fail'
      output.comments << "FAILURE: detected that there might be a persistence policy, but it failed expectations for resolvability.\n"
    else
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: was unable to find a persistence policy using any approach.\n"
    end

    output.createEvaluationResponse
  end

  def self.test_FM_A2_M_MetaLong_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_A2_M_MetaLong_meta)
    api.get_api
  end

  def self.test_FM_A2_M_MetaLong_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_A2_M_MetaLong_meta)
    dcat.get_dcat
  end
end
