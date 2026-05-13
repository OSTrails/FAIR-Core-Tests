class FAIRTest
  def self.test_FM_F4_M_MetaIndexed_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Searchable in major search engine',
      testid: 'test_FM_F4_M_MetaIndexed',
      description: "Tests whether a machine is able to discover the
      resource by search, using Microsoft Bing.  The process is to first
      identify the title of the resource in the metadata, then search for
      that title in Bing, and then check whether any of the results from
      Bing include a reference to the resource.  This test is designed to
      check whether the metadata is indexed in a major search engine, which
      is an important aspect of findability.  The test will also check for
      keywords in the metadata and use those as search terms as well.  The properties
      used to identify titles in linked data are dc:title, dcterms:title,
      dcterms:alternative, schema:name, schema:headline, schema:alternateName,
      schemah:name, schemah:headline, schemah:alternateName, rdfs:label,
      skos:prefLabel, skos:altLabel, foaf:name and bibo:title.
      The properties used to identify
      keywords in linked data are any property containing 'keyword' in the name.",
      metric: 'https://w3id.org/fair-metrics/general/FM_F4_M_MetaIndexed',
      indicators: 'https://doi.org/10.25504/FAIRsharing.0c0d21',
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

  def self.test_FM_F4_M_MetaIndexed(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_F4_M_MetaIndexed_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_F4_M_MetaIndexed_meta[:testversion]}'\n"

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
    # properties = FAIRChampionHarvester::Core.deep_dive_properties(hash)
    # #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    ###################  TITLE
    output.comments << "INFO: testing any linked data metadata for a key matching 'title' in any case.\n"

    titlequery = SPARQL.parse("
PREFIX dc:      <http://purl.org/dc/elements/1.1/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX schema:  <https://schema.org/>
PREFIX schemah: <http://schema.org/>
PREFIX rdfs:    <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX foaf:    <http://xmlns.com/foaf/0.1/>
PREFIX bibo:    <http://purl.org/ontology/bibo/>

SELECT DISTINCT ?subject ?titleProperty ?title WHERE {
  VALUES ?titleProperty {
    dc:title
    dcterms:title
    dcterms:alternative
    schema:name
    schema:headline
    schema:alternateName
    schemah:name
    schemah:headline
    schemah:alternateName
    rdfs:label
    skos:prefLabel
    skos:altLabel
    foaf:name
    bibo:title
  }
  ?subject ?titleProperty ?title .
  FILTER ( isLiteral(?title) )
}
ORDER BY ?subject ?titleProperty")

    titles = []
    graph.query(titlequery).each do |solution|
      titles << solution[:title].to_s
    end

    output.comments << "INFO: testing any hash-style metadata for a key matching 'title' in any case.\n"
    flatlist = hash.flatten(40) # hopefully no hash is more than 40 deep!
    for x in 1..flatlist.length
      term = flatlist[x - 1]
      next unless term.is_a? String

      # warn term
      if term.match(/title$/i) # in a flattened hash, find something matching 'title' at the end of the term
        titles << flatlist[x] # the next thing should be the title
      end
    end
    unless titles.first
      output.comments << "WARN: could not find a structured reference to the title in the hash-style metadata.\n"
    end

    titles.each do |title|
      output.comments << "INFO: found title #{title}.  Searching Bing\n"
      warn "Calling Bing with title #{title}\n\n"

      searchresults = callBing2(title, output)
      h = JSON.parse(searchresults)
      if h['webPages']
        output.comments << "INFO: found matches in Bing.  Checking for results that match any of #{finalURI.map do |b|
          b.to_s
        end}.\n"
        finalURI = finalURI.map { |b| b.downcase } # make case insensitive search
        h['webPages']['value'].each do |p|
          if finalURI.include?(p['url'].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
            output.comments << "SUCCESS: found a search record referencing #{p['url']} based on an exact-match title search against Bing.\n  "
            output.score = 'pass'
          end
        end
        unless output.score == 'pass'
          output.comments << "INFO: No results from Bing included any of #{finalURI.map { |b| b.to_s }}.\n"
        end
      else
        output.comments << "WARN:  Bing search for #{title} found no results.\n"
      end
    end

    #############  Keywords

    keywordquery = SPARQL.parse("
    PREFIX dc:      <http://purl.org/dc/elements/1.1/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX dcat:    <http://www.w3.org/ns/dcat#>
PREFIX schema:  <https://schema.org/>
PREFIX schemah: <http://schema.org/>
PREFIX foaf:    <http://xmlns.com/foaf/0.1/>
PREFIX prism:   <http://prismstandard.org/namespaces/basic/2.0/>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX rdfs:    <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?subject ?keywordProperty ?keyword WHERE {

  VALUES ?keywordProperty {
    dc:subject
    dcterms:subject
    dcat:keyword
    dcat:theme
    schema:keywords
    schema:about
    schema:genre
    schemah:keywords
    schemah:about
    schemah:genre
    foaf:topic
    prism:keyword
  }

  # Case 1: property value is already a plain string
  {
    ?subject ?keywordProperty ?keyword .
    FILTER ( isLiteral(?keyword) )
  }
  UNION
  # Case 2: property value is a URI — follow it to get a human-readable label
  {
    ?subject ?keywordProperty ?concept .
    FILTER ( isIRI(?concept) )
    VALUES ?labelProp {
      skos:prefLabel
      skos:altLabel
      rdfs:label
      schema:name
      schemah:name
    }
    ?concept ?labelProp ?keyword .
    FILTER ( isLiteral(?keyword) )
  }

}
ORDER BY ?subject ?keywordProperty")

    keywords = []
    graph.query(keywordquery).each do |solution|
      keywords << solution[:keyword].to_s
    end

    flatlist = hash.flatten(40) # hopefully no hash is more than 40 deep!
    for x in 1..flatlist.length
      term = flatlist[x - 1]
      # warn term
      next unless term.is_a? String

      if term.match(/keywords?$/i) # in a flattened hash, find something matching 'keywords?' at the end of the term
        keywords << flatlist[x] # the next thing should be the keywords
      end
    end

    keywords = keywords.join(' ').gsub(',', '')
    unless keywords =~ /\w+/
      output.comments << "WARN: could not find any human-readeable keywords in hash-style metadata.\n"
    end

    if keywords =~ /\w+/
      output.comments << "INFO: found keywords #{keywords}.  Now searching Bing.\n"
      warn "Calling Bing with keywords #{keywords}\n\n"

      searchresults = callBing2(keywords, output) # search bing
      h = JSON.parse(searchresults)
      if h['webPages']
        output.comments << "INFO: found matches in Bing.  Checking for results that match any of #{finalURI.map do |b|
          b.to_s
        end}\n"
        finalURI = finalURI.map { |b| b.downcase } # make case insensitive search
        h['webPages']['value'].each do |p|
          if finalURI.include?(p['url'].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
            output.comments << "SUCCESS: found a search hit matching #{p['url']} using metadata keywords in search on Bing.\n  "
            output.score = 'pass'
          end
        end
        unless output.score == 'pass'
          output.comments << "INFO: No keyword search results from Bing included any of #{finalURI.map do |b|
            b.to_s
          end}.\n"
        end
      else
        output.comments << "INFO: Bing returned no search results for keywords #{keywords}.\n"
      end
    end

    unless output.score == 'pass'
      output.comments << "FAILURE: Was unable to discover the metadata record by search in Bing using any method\n"
    end

    output.createEvaluationResponse
  end

  def self.callBing2(phrase, output)
    warn "Calling Bing with phrase #{phrase}\n\n"
    phrase = phrase.dup if phrase.frozen?
    phrase.gsub!(%r{https?://[^,]+}, '') # need to eliminate URLs that appear as keywords
    uri = 'https://api.cognitive.microsoft.com'
    path = '/bing/v7.0/search'

    accesskey = ENV['BING_API'] || 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

    if accesskey.length != 32
      warn 'Invalid Bing Search API subscription key!'
      warn 'Please add this to your environment.'
      abort
    end
    if accesskey == 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
      output.comments << "WARN: The Bing API access key  was not set.  This test will surely fail.\n"
    end
    #	escapedphrase = Addressable::URI.encode(phrase)
    escapedphrase = CGI.escape(phrase)
    if escapedphrase.length > 1500
      escapedphrase = escapedphrase[0..1500] # microsoft suggested maximum query length
      match = escapedphrase.match(/(.*)(%.*)/) # trim off any partially escaped things at the end
      escapedphrase = match[1] if match[1]
    end

    uri = URI(uri + path + "?q=#{escapedphrase}&count=50")
    # warn "HTTP URI: #{uri}"

    request = Net::HTTP::Get.new(uri)
    request['Ocp-Apim-Subscription-Key'] = accesskey

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    # warn "HTTP response: #{response.inspect}"
    response.body
  end

  def self.test_FM_F4_M_MetaIndexed_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_F4_M_MetaIndexed_meta)
    api.get_api
  end

  def self.test_FM_F4_M_MetaIndexed_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_F4_M_MetaIndexed_meta)
    dcat.get_dcat
  end
end
