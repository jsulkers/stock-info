# stock-info

## Running ##

### Scraper ###
ruby scraper.rb 
-> just runs the scraping functionality. Scraper saves all stocks that fit the criteria into stocks.json for consumption by the reader.
-> mystocks is a list of currently purchased stocks used in the scraper for marking stocks as purchased (and pulling purchased stocks that don't match criteria i.e. danger stocks)

### Reader ###
ruby reader.rb 
-> just runs the reader functionality. Reader reads stocks.json, uses the template.html.erb to create the index.html.

### Both ###
ruby compile_stocks.rb 
-> will run the scraper first, followed by the reader

### Scheduler ###
config/schedule.rb 
-> uses the whenever gem to create a cron job for running the compile_stocks.rb
-> run: whenever --update-crontab
-> crontab -l

### Current usage ###
Start up an ec2 instance 
scp files onto the box
Open port 80 
ruby -run -e httpd . -p 80 &


