class FAIRTest
  def self.test_FM_A1_2_M_DataAuth_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Data Authorization',
      testid: 'test_FM_A1_2_M_DataAuth',
      description: 'If the resolution protocol for the Data supports authentication and authorization for access to restricted content.',
      keywords: ['FAIR Assessment', 'Authentication', 'Authorization', 'FAIR Principles'],
      metric: 'https://w3id.org/fair-metrics/general/FM_A1-2_M_Auth',

      indicators: 'https://doi.org/10.25504/FAIRsharing.8e0027',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
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

  def self.test_FM_A1_2_M_DataAuth(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_A1_2_M_DataAuth_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_A1_2_M_DataAuth_meta[:testversion]}'\n"

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

    properties = FAIRChampionHarvester::Core.deep_dive_properties(hash)

    output.comments << "INFO: Searching metadata for likely identifiers to the data record\n"
    id_hash = id_graph = nil # set to nil for now

    properties.each do |keyval|
      (key, value) = keyval
      key = key.to_s

      output.comments << "INFO: Searching hash-style metadata for keys indicating a pointer to data.\n"
      FAIRChampionHarvester::Utils::DATA_PREDICATES.each do |prop|
        prop =~ %r{.*[#/]([^#/]+)$}
        prop = Regexp.last_match(1)
        output.comments << "INFO: Searching for key: #{prop}.\n"
        next unless key == prop

        output.comments << "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
        # warn "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
        id_hash = value.to_s
      end
    end

    if metadata.graph.size > 0 # have we found anything yet?
      output.comments << "INFO: Searching Linked Data metadata for predicates indicating a pointer to data.\n"
      id_graph = FAIRChampionHarvester::CommonQueries::GetDataIdentifier(graph: metadata.graph)
      warn "\n\nfound identifier #{id_graph} \n\n"
    end

    if id_hash.nil? && id_graph.nil?
      output.comments << "FAILURE: No data identifier was found in the metadata record.\n"
      output.score = 'fail'
      return output.createEvaluationResponse
    end

    metadata2 = FAIRChampionHarvester::Core.typeit(id_hash || id_graph)

    if metadata2
      output.comments << "SUCCESS: The data identifier #{@identifier} is recognized as a #{metadata2}, which is resolvable by an protocol that allows authorization/authentication.\n"
      output.score = 'pass'
    else
      output.comments << "INDETERMINATE: The data identifier #{@identifier} did not match any known identification system.\n"
      output.score = 'indeterminate'
    end
    output.createEvaluationResponse
  end

  def self.test_FM_A1_2_M_DataAuth_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_A1_2_M_DataAuth_meta)
    api.get_api
  end

  def self.test_FM_A1_2_M_DataAuth_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_A1_2_M_DataAuth_meta)
    dcat.get_dcat
  end
end
