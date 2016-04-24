require 'nokogiri'
require 'open-uri'
require 'json'

@file

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

    market_value = key_statistics.css("#yfi_rt_quote_summary").css("div")[4].css("span")[0].text.split(',').join.to_f

    if market_value > 2
        return
    end

    book_value_per_share = key_statistics.css("table")[18].css("tr")[7].css("td")[1].text.split(',').join.to_f

    if book_value_per_share < market_value
        return
    end

    if market_value.to_f > (book_value_per_share * 0.66)
        return
    end

    percentage_of_book_value = (market_value.to_f / book_value_per_share.to_f).round(2)

    income_statement = Nokogiri::HTML(open("http://finance.yahoo.com/q/bs?s=#{symbol}+Balance+Sheet&annual"))

    strong_elements = income_statement.css("strong")

    assets_2015 = strong_elements[7].text.split(',').join.to_f unless strong_elements[7].nil?
    liabilities_2015 = strong_elements[16].text.split(',').join.to_f unless strong_elements[16].nil?

    if assets_2015.nil? || liabilities_2015.nil?
        return
    end

    if (assets_2015 - (2.0 * liabilities_2015)) < 0
        return
    end
    
    assets_2014 = strong_elements[8].text.split(',').join.to_f
    assets_2013 = strong_elements[9].text.split(',').join.to_f

    if assets_2015.nil? || assets_2015 < 0
        return
    end

    average_assets = 0
    difference_to_average = 0
    
    if !assets_2014.nil? && !assets_2013.nil?
        average_assets = ((assets_2015 + assets_2014 + assets_2013) / 3).round(2)

        difference_to_average = (assets_2015 - average_assets).round(2)
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
        "assets_2015" => assets_2015,
        "liabilities_2015" => liabilities_2015,
        "difference_to_average" => difference_to_average,
        "website" => website
    }

    puts "CompanyHash: " + company_hash.to_json

    return company_hash
end

def read_companies companies, sector, sub_sector
    companies.shift

    companies_array = []

    companies.each do |company|
        company_hash = read_company company, sector, sub_sector

        if !company_hash.nil?
            companies_array << company_hash
        end
    end

    return companies_array

end

def read_sub_sector sub_sector, sector
    link = sub_sector.css("td a")
    
    companies = []

    if !link[0].nil?
        name = link[0].text + "\n"
        href = link[0]['href']

        name = name.gsub(/\s+/, "").delete('\//\s+/').squeeze('').to_s

        company_doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/#{href}"))

        companies = read_doc company_doc

        4.times {
            companies.shift
        }
        
        companies = read_companies(companies, sector, name)
    end

    sector_hash = {
        "#{name}" => companies
    }

    return sector_hash

end

def read_sub_sectors sub_sectors, sector
    
    pulled_sub_sectors = []

    sub_sectors.each do |sub_sector|
        pulled_sub_sectors << read_sub_sector(sub_sector, sector)
    end

    return pulled_sub_sectors
end

def read_sector sector_href
    link = sector_href.css("a")
    name = link.text
    href = link[0]['href']

    name = name.gsub(/\s+/, "").to_s

    sector_doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/#{href}"))

    sub_sectors = read_doc(sector_doc)

    pulled_sub_sectors = read_sub_sectors(sub_sectors, name)

    sub_sectors_hash  = {
        "#{name}" => pulled_sub_sectors
    }

    return sub_sectors_hash
    
end

def read_sectors sectors
    sectors.shift

    pulled_sectors = []

    sectors.each do |sector|
        pulled_sectors << read_sector(sector)
    end

    stocks = {
        "Sectors" => pulled_sectors
    }

    @file = File.open("stocks.json", 'w') 
    @file.write(stocks.to_json)
end

doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/s_conameu.html"))    

sectors = read_doc doc
read_sectors sectors

puts "Done."