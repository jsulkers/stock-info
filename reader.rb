require 'json'
require 'erb'
require 'date'

class Reader

	def initialize
		@filename = "stocks.json"
	end
	def run
		puts "Reading..."
		file = File.read("#{@filename}")

		@company_json = JSON.parse(file)

		template_file = File.open("template.html.erb", 'r').read
		erb = ERB.new(template_file)

		@read_date = DateTime.now.strftime("%a %b %d - %H:%M")
		File.open("index.html", 'w+') { |file| file.write(erb.result(binding)) }

		puts "Done."
	end
end

reader = Reader.new
reader.run