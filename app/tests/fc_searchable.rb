# Raised by callSearxngFcSearchable when the SearXNG backend itself is unreachable
# or misbehaving (network failure, non-2xx response, unparseable/malformed JSON).
# Callers rescue this specifically so a SearXNG outage produces an
# 'indeterminate' test result instead of an unhandled 500.
#
# Deliberately kept separate from test_FM_F4_M_MetaIndexed's own SearXNG client
# and error class: fc_searchable is expected to be deprecated, and the two
# should not share code that would break FM_F4 when fc_searchable is removed.
class FcSearchableSearxngError < StandardError; end

class FAIRTest
  def self.fc_searchable_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Searchable in major search engine',
      testid: 'fc_searchable',
      description: 'Tests whether a machine is able to discover the resource using a SearXNG metasearch service.',
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

  def self.fc_searchable(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: fc_searchable_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_searchable_meta[:testversion]}'\n"

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

    # URLs that may identify the assessed resource. The original implementation
    # referenced `finalURI` without ever assigning it, which causes a nil.map
    # failure as soon as a search engine returns results.
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
    output.comments << "INFO: testing any hash-style metadata for a key matching 'title' in any case.\n"
    flatlist = hash.flatten(40) # hopefully no hash is more than 40 deep!
    title = ''
    for x in 1..flatlist.length
      term = flatlist[x - 1]
      next unless term.is_a? String

      # warn term
      if term.match(/title$/i) # in a flattened hash, find something matching 'title' at the end of the term
        title = flatlist[x] # the next thing should be the title
        break
      end
    end
    unless title =~ /\w+/
      output.comments << "WARN: could not find a structured reference to the title in the hash-style metadata.\n"
    end

    if title =~ /\w+/
      output.comments << "INFO: found title #{title}.  Searching SearXNG\n"
      warn "Calling SearXNG with title #{title}\n\n"

      searchresults = callSearxngFcSearchable(title, output)
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
    flatlist = hash.flatten(40) # hopefully no hash is more than 40 deep!
    keywords = ''
    for x in 1..flatlist.length
      term = flatlist[x - 1]
      # warn term
      next unless term.is_a? String

      if term.match(/keywords?$/i) # in a flattened hash, find something matching 'keywords?' at the end of the term
        keywords = flatlist[x] # the next thing should be the keywords
        break
      end
    end
    # keywords = keywords.gsub!("\,", "")
    unless keywords =~ /\w+/
      output.comments << "WARN: could not find any human-readeable keywords in hash-style metadata.\n"
    end

    if keywords =~ /\w+/
      output.comments << "INFO: found keywords #{keywords}.  Now searching SearXNG.\n"
      warn "Calling SearXNG with hash keywords #{keywords}\n\n"

      searchresults = callSearxngFcSearchable(keywords, output)
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

    #####################  now with the graph data

    g = metadata.graph

    if g.size > 0 # have we found anything
      output.comments << "INFO: Testing Linked Data-formatted metadata for any predicate that contains 'title' in any case.\n "
      query = SPARQL.parse("select distinct ?o where {?s ?p ?o  FILTER(CONTAINS(lcase(str(?p)), 'title'))}") # find predicate containing "title", take object
      results = query.execute(g)
      if results.any?
        output.comments << "INFO: found title predicate.\n "
        seen = Hash.new(false)  # appaerntly, distinct isn't working in the sparql...??
        results.each do |res|
          next if seen[res[:o].to_s]

          seen[res[:o].to_s] = true

          title = res[:o].to_s  # get the title
          output.comments << "INFO: found possible Title:  #{title}.\n "
          # warn "looking for #{title}"
          output.comments << "INFO: Calling SearXNG search using #{title}.\n "
          warn "Calling SearXNG with graph title #{title}\n\n"

          searchresults = callSearxngFcSearchable(title, output) # search searxng
          # warn JSON::pretty_generate(JSON(searchresults))
          h = JSON.parse(searchresults) # parse json
          if h['results']&.any? # are there results
            output.comments << "INFO: SearXNG found results for#{title}.  Checking for results that match #{target_uris.map do |b|
              b.to_s
            end}.\n"
            h['results'].each do |p| # for each matching pge do
              if p['url'] && target_uris.include?(p['url'].to_s.downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
                output.comments << "SUCCESS: found a search record referencing #{p['url']} based on an exact-match title search against SearXNG.\n  "
                output.score = 'pass'
              end
            end
            unless output.score == 'pass'
              output.comments << "INFO: No results from SearXNG included any of #{target_uris.map { |b| b.to_s }}.\n"
            end
          else
            output.comments << "INFO: No search results from SearXNG using the title of the record\n  "
          end
        end
      end
      query = SPARQL.parse("select distinct ?o where {?s ?p ?o  FILTER(CONTAINS(lcase(str(?p)), 'name'))}") # find predicate containing "name", take object
      results = query.execute(g)
      if results.any?
        output.comments << "INFO: found a 'name' predicate; presuming this is a pointer to a title.\n "
        seen = Hash.new(false)  # appaerntly, distinct isn't working in the sparql...??
        results.each do |res|
          next if seen[res[:o].to_s]

          seen[res[:o].to_s] = true
          title = res[:o].to_s  # get the title
          output.comments << "INFO: found possible Title:  #{title}.\n "
          # warn "looking for #{title}"
          output.comments << "INFO: Calling SearXNG search using #{title}.\n "
          warn "Calling SearXNG with graph name #{title}\n\n"

          searchresults = callSearxngFcSearchable(title, output) # search searxng
          # warn JSON::pretty_generate(JSON(searchresults))
          h = JSON.parse(searchresults) # parse json
          if h['results']&.any? # are there results
            output.comments << "INFO: SearXNG found results for#{title}.  Checking for results that match #{target_uris.map do |b|
              b.to_s
            end}.\n"
            h['results'].each do |p| # for each matching pge do
              if p['url'] && target_uris.include?(p['url'].to_s.downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
                output.comments << "SUCCESS: found a search record referencing #{p['url']} based on an exact-match title search against SearXNG.\n  "
                output.score = 'pass'
              end
            end
            unless output.score == 'pass'
              output.comments << "INFO: No results from SearXNG included any of #{target_uris.map { |b| b.to_s }}.\n"
            end
          else
            output.comments << "INFO: No search results from SearXNG\n  "
          end
        end
      end
    end

    #######  keywords in graph

    g = metadata.graph

    if g.size > 0 # have we found anything
      output.comments << "INFO: Testing Linked Data-formatted metadata for any predicate that contains 'keyword' in any case.\n "
      query = SPARQL.parse("select distinct ?o where {?s ?p ?o  FILTER(CONTAINS(lcase(str(?p)), 'keyword'))}") # find predicate containing "title", take object
      results = query.execute(g)
      if results.any?
        seen = Hash.new(false) # appaerntly, distinct isn't working in the sparql...??
        results.each do |res|
          next if seen[res[:o].to_s]

          seen[res[:o].to_s] = true
          keywords = res[:o].to_s # get the keywords
          output.comments << "INFO: found keywords.\n "
          output.comments << "INFO: found keywords #{keywords}.\n "
          output.comments << "INFO: Calling SearXNG search using #{keywords}.\n "
          warn "Calling SearXNG with graph keywords #{keywords}\n\n"

          searchresults = callSearxngFcSearchable(keywords, output) # search searxng
          h = JSON.parse(searchresults) # parse json; malformed/non-JSON responses raise FcSearchableSearxngError from callSearxngFcSearchable

          if h['results']&.any? # are there results
            output.comments << "INFO: SearXNG found matches using #{keywords}. Testing matches for a reference to #{target_uris.map do |b|
              b.to_s
            end}\n"
            h['results'].each do |p| # for each matching pge do
              if p['url'] && target_uris.include?(p['url'].to_s.downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
                output.comments << "SUCCESS: found a search record referencing #{p['url']} based on a keyword search against SearXNG.\n  "
                output.score = 'pass'
              end
            end
            unless output.score == 'pass'
              output.comments << "INFO: No results from SearXNG included any of #{target_uris.map { |b| b.to_s }}.\n"
            end
          else
            output.comments << "INFO: No results from SearXNG using keywords #{keywords}.\n"
          end
        end
      end
    end

    unless output.score == 'pass'
      output.comments << "FAILURE: Was unable to discover the metadata record by search in SearXNG using any method\n"
    end
    rescue FcSearchableSearxngError => e
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: SearXNG search could not be completed: #{e.message}.\n"
    end

    output.createEvaluationResponse
  end

  # Queries a SearXNG metasearch instance (self-hosted, see docker-compose.searxng.yml)
  # in place of the old paid Bing Web Search API. SEARXNG_URL defaults to the
  # in-network container name 'searxng' and should always point at a private/
  # self-hosted instance: this method fires several queries per test run (one per
  # discovered title/keyword/name), and pointing it at a public SearXNG instance
  # would leak resource metadata to a third party and risk that instance banning
  # our IP for automated traffic.
  def self.callSearxngFcSearchable(phrase, output)
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
      raise FcSearchableSearxngError, message
    end

    begin
      parsed = JSON.parse(response.body)
    rescue JSON::ParserError => e
      message = "SearXNG returned invalid JSON: #{e.message}"
      output.comments << "ERROR: #{message}.\n"
      raise FcSearchableSearxngError, message
    end

    unless parsed['results'].is_a?(Array)
      message = 'SearXNG JSON response does not contain a results array'
      output.comments << "ERROR: #{message}.\n"
      raise FcSearchableSearxngError, message
    end

    response.body
  rescue URI::InvalidURIError, SocketError, SystemCallError, Timeout::Error => e
    message = "SearXNG request failed: #{e.message}"
    output.comments << "ERROR: #{message}.\n"
    raise FcSearchableSearxngError, message
  end

  def self.fc_searchable_api
    api = FtrRuby::OpenAPI.new(meta: fc_searchable_meta)
    api.get_api
  end

  def self.fc_searchable_about
    dcat = FtrRuby::DCAT_Record.new(meta: fc_searchable_meta)
    dcat.get_dcat
  end
end
