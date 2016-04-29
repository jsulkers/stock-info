require 'nokogiri'
require 'open-uri'
require 'json'
require 'date'

class Scraper

    def initialize
        puts "Initializing scraper..."
        @filename = "stocks.json"
        @file
        @companies = []
        @generated_date = DateTime.now.strftime("%a %b %d - %H:%M")
        puts "Scraper initialized @ #{@generated_date}."
    end

    def read_doc doc
        sectors_table = doc.css("body table")[4]
        sectors = sectors_table.css("tr")

        return sectors
    end

    def read_company company, sector, sub_sector
        company_row = company.css("td")
        
        name = company_row[0].css("a")[0].text unless company_row[0].css("a")[0].nil?
        symbol = company_row[0].css("a")[1].text unless company_row[0].css("a")[1].nil?
        pe = company_row[3].text unless company_row[3].nil?
        
        name = name.gsub(/\s+/, "").delete('\/').squeeze('').to_s
        symbol = symbol.to_s
        pe = pe.to_s

        if pe.eql? "NA"
            return
        end

        key_statistics = Nokogiri::HTML(open("http://finance.yahoo.com/q/ks?s=#{symbol}+Key+Statistics"))

        quote_summary = key_statistics.css("#yfi_rt_quote_summary")

        if quote_summary.nil?
            return
        end 

        quote_summary_div = quote_summary.css("div")[4]

        if quote_summary_div.nil?
            return
        end

        quote_summary_div_span = quote_summary_div.css("span")[0]

        if quote_summary_div_span.nil?
            return
        end

        market_value = quote_summary_div_span.text.split(',').join.to_f

        if market_value > 2 || market_value <= 0
            return
        end

        tables = key_statistics.css("table")[18]
        if tables.nil? 
            return 
        end

        tables_tr = tables.css("tr")[7]
        if tables_tr.nil? 
            return 
        end

        tables_tr_td = tables_tr.css("td")[1]
        if tables_tr_td.nil? 
            return 
        end

        book_value_per_share = tables_tr_td.text.split(',').join.to_f

        if book_value_per_share < market_value
            return
        end

        if market_value.to_f > (book_value_per_share * 0.66)
            return
        end

        percentage_of_book_value = (market_value.to_f / book_value_per_share.to_f).round(2)

        income_statement = Nokogiri::HTML(open("http://finance.yahoo.com/q/bs?s=#{symbol}+Balance+Sheet&annual"))

        strong_elements = income_statement.css("strong")

        assets_last_year = strong_elements[7].text.split(',').join.to_f unless strong_elements[7].nil?
        liabilities_last_year = strong_elements[16].text.split(',').join.to_f unless strong_elements[16].nil?

        if assets_last_year.nil? || liabilities_last_year.nil?
            return
        end

        if (assets_last_year - (2.0 * liabilities_last_year)) < 0
            return
        end
        
        assets_two_years = strong_elements[8].text.split(',').join.to_f
        assets_three_years = strong_elements[9].text.split(',').join.to_f

        if assets_last_year.nil? || assets_last_year < 0
            return
        end

        average_assets = 0
        difference_to_average = 0
        
        if !assets_two_years.nil? && !assets_three_years.nil?
            average_assets = ((assets_last_year + assets_two_years + assets_three_years) / 3).round(2)

            difference_to_average = (assets_last_year - average_assets).round(2)
        end

        if difference_to_average <= 0
            return
        end

        profile = Nokogiri::HTML(open("http://finance.yahoo.com/q/pr?s=#{symbol}+Profile"))

        website = profile.css("table a")[1].text unless profile.css("table a")[1].nil?

        company_hash = {
            "name" => name,
            "symbol" => symbol,
            "market_value" => market_value,
            "pe" => pe,
            "sector" => sector,
            "sub_sector" => sub_sector,
            "book_value_per_share" => book_value_per_share,
            "percentage_of_book_value" => percentage_of_book_value,
            "assets_last_year" => assets_last_year,
            "liabilities_last_year" => liabilities_last_year,
            "difference_to_average" => difference_to_average,
            "website" => website
        }

        @companies << company_hash

        puts "CompanyHash: " + company_hash.to_json
    end

    def read_companies companies, sector, sub_sector
        companies.shift

        companies.each do |company|
            read_company company, sector, sub_sector
        end
    end

    def read_sub_sector sub_sector, sector
        link = sub_sector.css("td a")

        if !link[0].nil?
            name = link[0].text + "\n"
            href = link[0]['href']

            name = name.gsub(/\s+/, "").delete('\//\s+/').squeeze('').to_s

            company_doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/#{href}"))

            companies = read_doc company_doc

            4.times {
                companies.shift
            }
            
           read_companies(companies, sector, name)
        end
    end

    def read_sub_sectors sub_sectors, sector

        sub_sectors.each do |sub_sector|
            read_sub_sector(sub_sector, sector)
        end
    end

    def read_sector sector_href
        link = sector_href.css("a")
        name = link.text
        href = link[0]['href']

        name = name.gsub(/\s+/, "").to_s

        sector_doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/#{href}"))

        sub_sectors = read_doc(sector_doc)

        read_sub_sectors(sub_sectors, name)
    end

    def read_sectors sectors
        sectors.shift

        sectors.each do |sector|
            read_sector(sector)
        end

        stocks = {
            "Companies" => @companies
        }

        puts "Writing to file #{@filename}"
        @file = File.open("#{@filename}", 'w') 
        @file.write(stocks.to_json)
        puts "Writing complete."
    end

    def run 
        puts "Running scraper..."
        doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/s_conameu.html"))    

        sectors = read_doc doc
        read_sectors sectors
        puts "Scrape complete."
    end
end



