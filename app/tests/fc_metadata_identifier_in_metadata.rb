class FAIRTest
  def self.fc_metadata_identifier_in_metadata_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Identifier Explicitly In Metadata',
      testid: 'fc_metadata_identifier_in_metadata',
      description: "Metric to test if the metadata contains the unique identifier to the metadata itself.  This is done using a variety of 'scraping' tools, including DOI metadata resolution, the use of the 'extruct' Python tool, and others.  The test is executed by searching for the predicates 'http[s]://purl.org/dc/terms/identifier','http[s]://schema.org/identifier.",
      metric: 'https://w3id.org/fair-metrics/general/FM_F3_M_MetaIdent',
      indicators: 'https://doi.org/10.25504/FAIRsharing.820324',
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

  def self.fc_metadata_identifier_in_metadata(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: fc_metadata_identifier_in_metadata_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_identifier_in_metadata_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    # hash = metadata.hash
    graph = metadata.graph
    # properties = FAIRChampion::Harvester.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    if graph.size > 0
      output.comments << "INFO: Linked Data Found.  Now searching for the metadata identifier using appropriate linked data predicates (#{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES}).\n"

      foundID = FAIRChampionHarvester::CommonQueries::GetSelfIdentifier(metadata.graph, output)

      # query pattern-match in an object position
      unless foundID.first
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record\n"
        return output.createEvaluationResponse  # release the result from all other tests
      end
      if foundID.first.empty?
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record using predicates #{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES}. \n"
        return output.createEvaluationResponse  # release the result from all other tests
      end
      unless foundID.first =~ /\w/
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record using predicates #{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES}. \n"
        return output.createEvaluationResponse  # release the result from all other tests
      end

    else
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: linked data metadata was not found, so its identifier could not be located. \n"
      return output.createEvaluationResponse
    end

    if foundID.include?(guid)
      output.score = 'pass'
      output.comments << "SUCCESS: the starting identifier (#{guid}) was found in the structured metadata\n"
    else
      output.score = 'fail'
      output.comments << "FAILURE: While (apparent) metadata record identifiers were found (#{foundID}) none of them matched the initial GUID provided to the test (#{guid}).  Exact identifier match is required.\n"
    end

    output.createEvaluationResponse
  end

  def self.fc_metadata_identifier_in_metadata_api
    api = FtrRuby::OpenAPI.new(meta: fc_metadata_identifier_in_metadata_meta)
    api.get_api
  end

  def self.fc_metadata_identifier_in_metadata_about
    dcat = FtrRuby::DCAT_Record.new(meta: fc_metadata_identifier_in_metadata_meta)
    dcat.get_dcat
  end
end
