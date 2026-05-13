class FAIRTest
  def self.test_FM_A1_1_M_OpenProt_Data_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Data Protocol',
      testid: 'test_FM_A1_1_M_OpenProt_Data',
      description: 'Data may be retrieved by an open and free protocol.
      Tests Data GUID (the identifier of the data that is being described by the metadata record)
      for its resolution protocol.
      Currently passes InChI Keys, DOIs, Handles, and URLs.
      Recognition of other identifiers will be added upon request by the community.',
      metric: 'https://w3id.org/fair-metrics/general/FM_A1-1_M_OpenProt',
      indicators: 'https://doi.org/10.25504/FAIRsharing.7612c1',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'protocols', 'FAIR Principles'],
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

  def self.test_FM_A1_1_M_OpenProt_Data(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_A1_1_M_OpenProt_Data_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_A1_1_M_OpenProt_Data_meta[:testversion]}'\n"

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

    output.comments << "INFO: Searching metadata for likely identifiers to the data record\n"
    identifier = nil

    properties.each do |keyval|
      (key, value) = keyval
      key = key.to_s

      output.comments << "INFO: Searching hash-style metadata for keys indicating a pointer to data.\n"
      FAIRChampionHarvester::Utils::DATA_PREDICATES.each do |prop|
        prop =~ %r{.*[#/]([^#/]+)$}
        prop = ::Regexp.last_match(1)
        output.comments << "INFO: Searching for key: #{prop}.\n"
        if key == prop
          output.comments << "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
          identifier = value.to_s
        end
      end
    end

    if graph.size > 0 # have we found anything yet?
      output.comments << "INFO: Searching Linked Data metadata for predicates indicating a pointer to data.\n"
      identifier = FAIRChampionHarvester::CommonQueries::GetDataIdentifier(graph: graph)
    end

    if identifier =~ /\w+/
      metadata2 = FAIRChampionHarvester::Core.typeit(identifier)
      if metadata2
        output.comments << "SUCCESS: The identifier #{@identifier} is recognized as a #{metadata2}, which is resolvable by an open and free protocol.\n"
        output.score = 'pass'
      else
        output.comments << "FAILURE: The identifier #{@identifier} did not match any known identification system.\n"
        output.score = 'fail'
      end
    else
      output.score = 'indeterminate'
      output.comments <<  "INFO: Tested the following #{FAIRChampionHarvester::Utils::DATA_PREDICATES}(or their plain JSON hash-key equivalents)\n"
      output.comments <<  'INDETERMINATE: Was unable to locate the data identifier in the metadata using any (common) property/predicate reserved for this purpose.'
    end
    output.createEvaluationResponse
  end

  def self.test_FM_A1_1_M_OpenProt_Data_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_A1_1_M_OpenProt_Data_meta)
    api.get_api
  end

  def self.test_FM_A1_1_M_OpenProt_Data_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_A1_1_M_OpenProt_Data_meta)
    dcat.get_dcat
  end
end
