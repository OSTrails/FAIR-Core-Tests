class FAIRTest
  def self.test_FM_R1_1_M_StdLic_strong_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Metadata Includes License (strong)',
      testid: 'test_FM_R1_1_M_StdLic_strong',
      description: "Maturity Indicator to test if the linked data metadata contains an explicit and correctly structured
      pointer to the license.  Tests for the presence of: [\"http://www.w3.org/1999/xhtml/vocab#license\", \"https://www.w3.org/1999/xhtml/vocab#license\", \"http://purl.org/ontology/dvia#hasLicense\", \"https://purl.org/ontology/dvia#hasLicense\", \"http://purl.org/dc/terms/license\", \"https://purl.org/dc/terms/license\", \"http://creativecommons.org/ns#license\", \"https://creativecommons.org/ns#license\", \"http://reference.data.gov.au/def/ont/dataset#hasLicense\", \"https://reference.data.gov.au/def/ont/dataset#hasLicense\"]
      and does some compliance testing on what is expected as the value of those properties.
      Note that this test only operates on linked data.  JSON and XML metadata are not tested by this test,
      but may be tested by the weaker version of this test.",
      metric: 'https://w3id.org/fair-metrics/general/FM_R1-1_M_StdLic',
      indicators: 'https://doi.org/10.25504/FAIRsharing.8e0027',
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

  def self.test_FM_R1_1_M_StdLic_strong(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_R1_1_M_StdLic_strong_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_R1_1_M_StdLic_strong_meta[:testversion]}'\n"

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
    output.score = 'fail'
    queries = %w[
      http://www.w3.org/1999/xhtml/vocab#license https://www.w3.org/1999/xhtml/vocab#license
      http://purl.org/ontology/dvia#hasLicense	https://purl.org/ontology/dvia#hasLicense
      http://purl.org/dc/terms/license	https://purl.org/dc/terms/license
      http://creativecommons.org/ns#license	https://creativecommons.org/ns#license
      http://reference.data.gov.au/def/ont/dataset#hasLicense	https://reference.data.gov.au/def/ont/dataset#hasLicense
    ]
    if g.size > 0 # have we found anything yet?
      output.comments << "INFO: Linked data found.  Testing for one of the following predicates: #{queries}.\n"
      queries.each do |predicate|
        output.comments << "INFO: testing #{predicate}.\n"
        query = SPARQL.parse('select ?o where {?s <' + predicate + '> ?o}')
        results = query.execute(g)
        next unless results.any?

        object = results.first[:o]
        if object.resource? && !object.anonymous?
          output.score = 'pass'
          output.comments << "SUCCESS: Found the #{predicate} predicate with a Resource as its value.\n"
        else
          output.comments << "WARN: Found the #{predicate} predicate, but it does not have a Resource as its value,
          thus is non-compliant.\n"
        end
      end

      output.comments << "INFO:  Testing for <https://schema.org/license>.\n"
      query = SPARQL.parse('select ?o where {?s <https://schema.org/license> ?o}')
      results = query.execute(g)
      if results.any?
        object = results.first[:o]
        if object.resource? && !object.anonymous?
          output.score = 'pass'
          output.comments << "SUCCESS: Found the Schema license predicate with a Resource as its value.\n"
        else
          output.comments << "WARN: Found the Schema license predicate, but it does not have a Resource as its value.
          While this is compliant with Schema, it is not best-practice.
          Please update your metadata to point to a URL containing the license.\n"
        end
      end

      output.comments << "INFO:  Testing for <http://schema.org/license>.\n"
      query = SPARQL.parse('select ?o where {?s <http://schema.org/license> ?o}')
      results = query.execute(g)
      if results.any?
        object = results.first[:o]
        if object.resource? && !object.anonymous?
          output.score = 'pass'
          output.comments << "SUCCESS: Found the Schema license predicate with a Resource as its value.\n"
        else
          output.comments << "WARN: Found the Schema license predicate, but it does not have a Resource as its value.  While this is compliant with Schema, it is not best-practice.  Please update your metadata to point to a URL containing the license.\n"
        end
      end

    else
      output.comments << 'WARN: No Linked Data metadata found.  '
    end

    if output.score == 'fail'
      output.comments << 'FAILURE: No correctly structured license property was found in the metadata.'
    end

    output.createEvaluationResponse
  end

  def self.test_FM_R1_1_M_StdLic_strong_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_R1_1_M_StdLic_strong_meta)
    api.get_api
  end

  def self.test_FM_R1_1_M_StdLic_strong_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_R1_1_M_StdLic_strong_meta)
    dcat.get_dcat
  end
end
