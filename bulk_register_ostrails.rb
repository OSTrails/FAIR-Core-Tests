require "rest-client"
require "json"
p = RestClient.get("https://tests.ostrails.eu/tests")

pattern = %r{href="/(tests/[^/]+)"}
warn "finding pattern #{pattern}"

# Find all matches
matches = p.scan(pattern)

# Output the matches
matches.each do |partial|
  warn "found #{partial}"
  address = "https://tests.ostrails.eu/#{partial.first}"
  warn address

  payload = {
    "clientUrl" => address
  }.to_json

  warn "PAYLOAD #{payload}"

  headers = {
    content_type: :json
  }
  url = "https://tools.ostrails.eu/fdp-index-proxy/proxy"

  begin
    response = RestClient.post(url, payload, headers)

    # Output the response
    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"
  rescue RestClient::ExceptionWithResponse => e
    # Handle errors
    puts "Error: #{e.response.code}"
    puts "Error Body: #{e.response.body}"
  rescue StandardError => e
    puts "An unexpected error occurred: #{e.message}"
  end
end
# curl -v -d '{"clientUrl": "https://tests.ostrails.eu/tests/fc_data_authorization"}'
# -H "Content-type: application/json"
# https://tools.ostrails.eu/fdp-index-proxy/proxy
