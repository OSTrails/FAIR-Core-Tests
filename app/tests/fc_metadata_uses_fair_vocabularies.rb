require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_uses_fair_vocabularies_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata uses FAIR vocabularies (strong)',
      testid: 'fc_metadata_uses_fair_vocabularies',
      description: 'Maturity Indicator to test if the linked data metadata uses terms that resolve to linked (FAIR) data.',
      metric: 'https://purl.org/fair-metrics/Gen2_FM_I2B',
      principle: 'I2'
    }
  end

  def self.fc_metadata_uses_fair_vocabularies(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: fc_metadata_uses_fair_vocabularies_meta[:testname],
      version: fc_metadata_uses_fair_vocabularies_meta[:testversion],
      description: fc_metadata_uses_fair_vocabularies_meta[:description],
      metric: fc_metadata_uses_fair_vocabularies_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_uses_fair_vocabularies_meta[:testversion]}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

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
    properties = FAIRChampion::Harvester.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    g = graph
    hosthash = {}
    preds = g.map do |s|
      s.predicate unless s.predicate.value =~ %r{1999/xhtml/} or s.predicate.value =~ /rdf-syntax-ns/
    end

    preds.compact!
    preds.each { |p| (hosthash[p.host] ||= []) << p }

    count = success = 0

    hosthash.keys.each do |host|
      predicate = hosthash[host].sort.first
      output.comment << "INFO:  Testing resolution of predicates from the domain #{host}\n"
      # $stderr.puts "testing host #{host}"
      count += hosthash[host].uniq.count

      case predicate.value
      when %r{purl.org/dc/} # these resolve very slowly, so just accept that they are ok!
        output.comment << "INFO:  resolution of DC predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      when %r{/vcard/} # these resolve very slowly, so just accept that they are ok!
        output.comment << "INFO:  resolution of VCARD predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      when %r{w3\.org/ns/dcat}
        output.comment << "INFO:  resolution of DCAT predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      when %r{xmlns\.com/foaf/}
        output.comment << "INFO:  resolution of FOAF predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      end

      output.comment << "INFO:  testing resolution of predicate #{predicate.value}\n"
      metadata2 = FAIRChampion::Utils.resolveit(predicate.value) # this  sends the content-negotiation for linked data
      g2 = metadata2.graph
      output.comment << if g2.size > 0
                          "INFO:  predicate #{predicate.value} resolved to linked data.\n"
                        else
                          "WARN:  predicate #{predicate.value} did not resolve to linked data.\n"
                        end

      output.comment << "INFO: If linked data was found in the previous line, it will now be tested by the following SPARQL query: 'select * where {<#{predicate.value}> ?p ?o}' \n"

      query = SPARQL.parse("select * where {<#{predicate.value}> ?p ?o}")
      results = query.execute(g2)
      if results.any?
        output.comment << "INFO: Resolving #{predicate.value}returned linked data, including that URI as a triple Subject.\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
      else
        output.comment << "WARN:  predicate #{predicate.value} was not found as the SUBJECT of a triple, indicating that it did not resolve to its definition.\n"
      end
    end

    if count > 0 and success >= count * 0.66
      output.comment << "SUCCESS: #{success} of a total of #{count} predicates discovered in the metadata resolved to Linked Data data.  This is sufficient to pass the test.\n"
      output.score = 'pass'
    elsif count == 0
      output.comment << "FAILURE: No predicates were found that resolved to Linked Data.\n"
      output.score = 'fail'
    else
      output.comment << "FAILURE: #{success} of a total of #{count} predicates discovered in the metadata resolved to Linked Data data.  The minimum to pass this test is 2/3 (with a minimum of 3 predicates in total).\n"
      output.score = 'fail'
    end
    output.createEvaluationResponse
  end

  def self.fc_metadata_uses_fair_vocabularies_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(title: fc_metadata_uses_fair_vocabularies_meta[:testname],
                      description: fc_metadata_uses_fair_vocabularies_meta[:description],
                      tests_metric: fc_metadata_uses_fair_vocabularies_meta[:metric],
                      version: fc_metadata_uses_fair_vocabularies_meta[:testversion],
                      applies_to_principle: fc_metadata_uses_fair_vocabularies_meta[:principle],
                      path: fc_metadata_uses_fair_vocabularies_meta[:testid],
                      organization: 'OSTrails Project',
                      org_url: 'https://ostrails.eu/',
                      responsible_developer: 'Mark D Wilkinson',
                      email: 'mark.wilkinson@upm.es',
                      developer_ORCiD: '0000-0001-6960-357X',
                      protocol: ENV.fetch('TEST_PROTOCOL', nil),
                      host: ENV.fetch('TEST_HOST', nil),
                      basePath: ENV.fetch('TEST_PATH', nil),
                      response_description: 'The response is "pass", "fail" or "indeterminate"',
                      schemas: schemas)

    api.get_api
  end
end
