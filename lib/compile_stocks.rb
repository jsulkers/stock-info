require_relative './scraper.rb'
require_relative './reader.rb'

scraper = Scraper.new
scraper.run

reader = Reader.new
reader.run

