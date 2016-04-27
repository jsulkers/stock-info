require 'json'
require 'erb'

file = File.read('stocks.json')

@company_json = JSON.parse(file)

template_file = File.open("template.html.erb", 'r').read
erb = ERB.new(template_file)

File.open("converted.html", 'w+') { |file| file.write(erb.result(binding)) }
