require 'rest-client'
require 'json'

r = RestClient.get('http://localhost:8282/tests', accept: 'application/json')
p = JSON.parse r
p.each do |t|
 next if t =~ /harvest/
  puts t
 resp = RestClient.post("http://localhost:8282/tests/assess/test/#{t}",{resource_identifier: "https://w3id.org/duchenne-fdp"})
 puts resp.code
end

