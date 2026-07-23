# Raised by callSearxngMetaIndexed when the SearXNG backend itself is unreachable
# or misbehaving (network failure, non-2xx response, unparseable/malformed JSON).
# Callers rescue this specifically so a SearXNG outage produces an
# 'indeterminate' test result instead of an unhandled 500.
#
# Deliberately independent of fc_searchable's own SearXNG client and error
# class: fc_searchable is expected to be deprecated, and this test should
# keep working unchanged when that happens.
class MetaIndexedSearxngError < StandardError; end

class FAIRTest
  def self.test_FM_F4_M_MetaIndexed_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-4.0.0',
      testname: 'OSTrails Core: Searchable in major search engine',
      testid: 'test_FM_F4_M_MetaIndexed',
      description: "Tests whether a machine is able to discover the
      resource by search, using a SearXNG metasearch service.  The process is to first
      identify the title of the resource in the metadata, then search for
      that title using SearXNG, and then check whether any of the results from
      SearXNG include a reference to the resource.  This test is designed to
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

    # URLs that may identify the assessed resource, used to check whether a
    # search result actually points back at the tested record.
    resolved_uris = if metadata.respond_to?(:finalURI)
                      metadata.finalURI
                    elsif metadata.respond_to?(:final_uri)
                      metadata.final_uri
                    elsif metadata.respond_to?(:uri)
                      metadata.uri
                    end

    target_uris = (Array(resolved_uris) + [guid]).compact
      .map { |value| value.to_s.strip.downcase }
      .reject(&:empty?)
      .uniq

    begin
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
      output.comments << "INFO: found title #{title}.  Searching SearXNG\n"
      warn "Calling SearXNG with title #{title}\n\n"

      searchresults = callSearxngMetaIndexed(title, output)
      h = JSON.parse(searchresults)
      if h['results']&.any?
        output.comments << "INFO: found matches in SearXNG.  Checking for results that match any of #{target_uris.map do |b|
          b.to_s
        end}.\n"
        h['results'].each do |p|
          if p['url'] && target_uris.include?(p['url'].to_s.downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
            output.comments << "SUCCESS: found a search record referencing #{p['url']} based on an exact-match title search against SearXNG.\n  "
            output.score = 'pass'
          end
        end
        unless output.score == 'pass'
          output.comments << "INFO: No results from SearXNG included any of #{target_uris.map { |b| b.to_s }}.\n"
        end
      else
        output.comments << "WARN:  SearXNG search for #{title} found no results.\n"
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
      output.comments << "INFO: found keywords #{keywords}.  Now searching SearXNG.\n"
      warn "Calling SearXNG with keywords #{keywords}\n\n"

      searchresults = callSearxngMetaIndexed(keywords, output) # search searxng
      h = JSON.parse(searchresults)
      if h['results']&.any?
        output.comments << "INFO: found matches in SearXNG.  Checking for results that match any of #{target_uris.map do |b|
          b.to_s
        end}\n"
        h['results'].each do |p|
          if p['url'] && target_uris.include?(p['url'].to_s.downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
            output.comments << "SUCCESS: found a search hit matching #{p['url']} using metadata keywords in search on SearXNG.\n  "
            output.score = 'pass'
          end
        end
        unless output.score == 'pass'
          output.comments << "INFO: No keyword search results from SearXNG included any of #{target_uris.map do |b|
            b.to_s
          end}.\n"
        end
      else
        output.comments << "INFO: SearXNG returned no search results for keywords #{keywords}.\n"
      end
    end

    unless output.score == 'pass'
      output.score = 'fail'
      output.comments << "FAILURE: Was unable to discover the metadata record by search in SearXNG using any method\n"
    end
    rescue MetaIndexedSearxngError => e
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: SearXNG search could not be completed: #{e.message}.\n"
    end

    output.createEvaluationResponse
  end

  # Queries a SearXNG metasearch instance (self-hosted, see docker-compose.searxng.yml)
  # in place of the old paid Bing Web Search API. SEARXNG_URL defaults to the
  # in-network container name 'searxng' and should always point at a private/
  # self-hosted instance: pointing it at a public SearXNG instance would leak
  # resource metadata to a third party and risk that instance banning our IP
  # for automated traffic.
  #
  # Intentionally a standalone copy of fc_searchable's callSearxngFcSearchable
  # rather than a shared helper: fc_searchable is expected to be deprecated,
  # and this test should keep working unchanged when that happens.
  def self.callSearxngMetaIndexed(phrase, output)
    warn "Calling SearXNG with phrase #{phrase}\n\n"

    phrase = phrase.to_s.dup
    phrase.gsub!(%r{https?://[^,]+}, '') # eliminate URLs that appear as keywords
    phrase = phrase.strip

    if phrase.empty?
      output.comments << "WARN: SearXNG query was empty after removing URLs.\n"
      return JSON.generate('results' => [])
    end

    endpoint = ENV.fetch('SEARXNG_URL', 'http://searxng:8080/search')
    uri = URI(endpoint)

    params = URI.decode_www_form(uri.query || '')
    params << ['q', phrase[0, 1500]]
    params << ['format', 'json'] # requires `search.formats: [html, json]` in searxng-config/settings.yml

    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    # SearXNG's bot/rate limiter keys off client IP; spoofing it to a fixed trusted
    # IP is harmless here only because searxng-config/settings.yml has `limiter: false`.
    # If the limiter is ever turned on, this stops being a no-op and starts being a
    # rate-limit bypass -- worth revisiting together at that point.
    client_ip = ENV.fetch('SEARXNG_CLIENT_IP', '127.0.0.1')
    request['X-Forwarded-For'] = client_ip
    request['X-Real-IP'] = client_ip

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: ENV.fetch('SEARXNG_OPEN_TIMEOUT', '5').to_i,
      read_timeout: ENV.fetch('SEARXNG_READ_TIMEOUT', '20').to_i
    ) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      message = "SearXNG returned HTTP #{response.code}: #{response.message}"
      output.comments << "ERROR: #{message}.\n"
      raise MetaIndexedSearxngError, message
    end

    begin
      parsed = JSON.parse(response.body)
    rescue JSON::ParserError => e
      message = "SearXNG returned invalid JSON: #{e.message}"
      output.comments << "ERROR: #{message}.\n"
      raise MetaIndexedSearxngError, message
    end

    unless parsed['results'].is_a?(Array)
      message = 'SearXNG JSON response does not contain a results array'
      output.comments << "ERROR: #{message}.\n"
      raise MetaIndexedSearxngError, message
    end

    response.body
  rescue URI::InvalidURIError, SocketError, SystemCallError, Timeout::Error => e
    message = "SearXNG request failed: #{e.message}"
    output.comments << "ERROR: #{message}.\n"
    raise MetaIndexedSearxngError, message
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
