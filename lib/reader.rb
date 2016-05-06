require 'json'
require 'erb'
require 'date'

# Reader class reads over a generated .json file and creates an
# index.html file from the erb template.
class Reader
  def initialize
    @filename = './data/stocks.json'
  end

  def run
    puts 'Reading...'
    json_file = File.read(@filename)

    @company_json = JSON.parse(json_file)

    template_file = File.open('./views/template.html.erb', 'r').read
    erb = ERB.new(template_file)

    @read_date = DateTime.now.strftime('%a %b %d - %H:%M')
    File.open('./views/index.html', 'w+') { |file| file.write(erb.result(binding)) }
    puts 'Done.'
  end
end

reader = Reader.new
reader.run
