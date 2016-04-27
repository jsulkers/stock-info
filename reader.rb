require 'json'
require 'erb'

file = File.read('stocks.json')

@company_json = JSON.parse(file)

# puts data_hash

# data_hash["Companies"].each do |company|
# 	puts company["name"]
# end

template_file = File.open("template.html.erb", 'r').read
erb = ERB.new(template_file)

File.open("converted.html", 'w+') { |file| file.write(erb.result(binding)) }
