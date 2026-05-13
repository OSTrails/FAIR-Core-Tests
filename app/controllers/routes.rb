def set_routes(classes: [])
  set :server_settings, timeout: 180
  set :public_folder, File.join(__dir__, '../public')
  set :port, 8282

  test_host = ENV.fetch('TEST_HOST')
  basepath = ENV.fetch('TEST_PATH')
  test_protocol = ENV.fetch('TEST_PROTOCOL')
  abort 'TEST_PATH not set in environment - cannot continue' unless basepath
  abort 'TEST_PROTOCOL not set in environment - cannot continue' unless test_protocol
  abort 'TEST_HOST not set in environment - cannot continue' unless test_host
  basepath = basepath.gsub(%r{^/}, '') # was frozen, so overwrite
  basepath = basepath.gsub(%r{/$}, '')
  warn "\n\nbasepath set to #{basepath}\n\n"

  get '/' do
    content_type :json
    response.body = JSON.dump(Swagger::Blocks.build_root_json(classes))
  end

  get %r{/#{basepath}/?} do
    ts = Dir["#{File.dirname(__FILE__)}/../tests/*.rb"]
    @tests = ts.map { |t| t.match(%r{.*/(\S+)\.rb$})[1] } # This is just the final field in the URL
    request.accept.each do |type|
      warn "accept #{type}"
      case type.to_s
      when 'application/json'
        content_type :json
        halt @tests.to_json
      when 'application/ld+json'
        content_type 'application/ld+json'
        halt @tests.to_json
      end
    end

    # def initialize(test_host:, basepath:, test_protocol:)
    infra = FtrRuby::TestInfra.new(test_host: test_host, basepath: basepath, test_protocol: test_protocol)
    @basepath = basepath
    @labels, @lps = infra.get_tests_metrics(tests: @tests) # the local URL is built in this routine, and called
    # warn "landing pages #{@lps.inspect}"
    halt erb :listtests, layout: :listtests_layout
  end

  post "/#{basepath}/assess/test/:id" do
    content_type :json
    id = params[:id]
    guid = ''
    if params['resource_identifier']
      guid = params['resource_identifier']
    else
      payload = JSON.parse(request.body.read)
      guid = payload['resource_identifier']
    end
    warn "now testing #{guid}"
    # begin
    @result = FAIRTest.send(id, guid: guid) # @result is a json STRING!

    if request.accept?('text/html') || request.accept?('application/xhtml+xml')
      content_type :html
      data = JSON.parse(@result)
      @test_execution = data['@graph'].find { |g| g['@type'] == 'ftr:TestExecutionActivity' }
      @test = data['@graph'].find { |g| g['@id'] == @test_execution['prov:wasAssociatedWith']['@id'] }
      @metric_implementation = @test['sio:SIO_000233'] # Extract SIO_000233
      @test_result = data['@graph'].find { |g| g['@type'] == 'ftr:TestResult' }
      @result_value = @test_result['prov:value']['@value'] # Extract pass/fail
      halt erb :testresult
    else
      # Assume JSON/LD — most permissive path
      content_type 'application/ld+json'
      halt @result
    end
    error 406
  end

  # ============================= GET ----
  # ============================= GET ----
  # ============================= GET ----
  # ============================= GET ----

  get "/#{basepath}/:id" do # returns DCAT
    warn "get '/#{basepath}/:id'"
    id = params[:id]
    idabout = "#{id}_about"
    begin
      warn "get #{idabout}"
      graph = FAIRTest.send(idabout)
    rescue StandardError
      halt 404, { 'error' => "Invalid test ID: #{params[:id]}" }.to_json
    end

    request.accept.each do |type|
      case type.to_s
      when 'text/turtle'
        content_type 'text/turtle'
        halt graph.dump(:turtle)
      when 'application/json'
        content_type :json
        halt graph.dump(:jsonld)
      when 'application/ld+json'
        content_type 'application/ld+json'
        halt graph.dump(:jsonld)
      else # for the FDP index send turtle by default
        content_type 'text/turtle'
        halt graph.dump(:turtle)
      end
    end
  end

  get "/#{basepath}/:id/api" do # return swagger
    content_type 'application/openapi+yaml'
    id = params[:id]
    idapi = id + '_api'
    begin
      @result = FAIRTest.send(idapi)
    rescue StandardError
      halt 404, { 'error' => "Invalid test ID: #{params[:id]}" }.to_json
    end
    @result
  end
end
