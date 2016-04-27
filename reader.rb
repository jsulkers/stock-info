require 'json'

file = File.read('stocks.json')

data_hash = JSON.parse(file)

puts data_hash

data_hash["Companies"].each do |company|
	puts company["name"]
end