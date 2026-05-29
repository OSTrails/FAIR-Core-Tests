require 'rspec/core'
require 'rspec'
require 'spec_helper'

RSpec.describe 'Minimal Test' do
  it 'runs a simple test' do
    expect(true).to eq(true)
  end
end

RSpec.describe 'API Routes' do
  describe 'GET /tests/' do
    it 'renders test list with metrics' do
      get '/tests/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('List and Execute Champion Tests')
      # $expect(last_response.body).to include('curl -H "Content-type: application/json" -H "Accept: application/json"')
    end
  end

  # Dynamically retrieve test IDs from app/tests/*.rb
  test_ids = Dir[File.join(File.dirname(__FILE__), '../../app/tests/*.rb')]
              .map { |t| t.match(%r{.*/(\S+)\.rb$})[1] }
              .reject { |id| id == 'env' }

  describe 'GET /tests/:id' do
    context 'with Turtle accept header' do
      test_ids.each do |test_id|
        it "returns DCAT RDF graph as Turtle for valid test ID: #{test_id}" do
          get "/tests/#{test_id}", {}, { 'HTTP_ACCEPT' => 'text/turtle' }
          expect(last_response).to be_ok
          expect(last_response.content_type).to include('text/turtle')
          expect(last_response.body).to include("<http://localhost:8282/tests/#{test_id}>")
          expect(last_response.body).to include('http://www.w3.org/ns/dcat#DataService')
          expect(last_response.body).to include('https://w3id.org/ftr#Test')
        end
      end

      it 'returns 404 for invalid test ID' do
        get '/tests/invalid_test', {}, { 'HTTP_ACCEPT' => 'text/turtle' }
        expect(last_response.status).to eq(404)
        expect(JSON.parse(last_response.body)).to include('error' => 'Invalid test ID: invalid_test')
      end
    end

    context 'with JSON-LD accept header' do
      test_ids.each do |test_id|
        it "returns DCAT RDF graph as JSON-LD for valid test ID: #{test_id}" do
          get "/tests/#{test_id}", {}, { 'HTTP_ACCEPT' => 'application/ld+json' }
          expect(last_response).to be_ok
          expect(last_response.content_type).to eq('application/ld+json')
          parsed_json = JSON.parse(last_response.body)
          expect(parsed_json).to include(
            hash_including(
              '@id' => "http://localhost:8282/tests/#{test_id}",
              '@type' => array_including('http://www.w3.org/ns/dcat#DataService', 'https://w3id.org/ftr#Test')
            )
          )
        end
      end
    end
  end

  describe 'GET /tests/:id/api' do
    it 'returns 404 for an invalid test id' do
      get '/tests/invalid_test/api'
      expect(last_response.status).to eq(404)
      expect(JSON.parse(last_response.body)).to include('error' => 'Invalid test ID: invalid_test')
    end
  end
end
