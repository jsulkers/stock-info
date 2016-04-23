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

    market_value = key_statistics.css("#yfi_rt_quote_summary").css("div")[4].css("span")[0].text

    if market_value.split(',').join.to_f > 10
        return
    end

    book_value_per_share = key_statistics.css("table")[18].css("tr")[7].css("td")[1].text

    company_hash = {
        "name" => name,
        "symbol" => symbol,
        "market_value" => market_value,
        "pe" => pe,
        "sector" => sector,
        "sub_sector" => sub_sector,
        "book_value_per_share" => book_value_per_share
    }

    puts "Company hash:\n" + company_hash.to_json

    if book_value_per_share.to_f > market_value.to_f
        return company_hash
    end
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

    puts "Companies array:\n" + companies_array.to_json

    return companies_array

end

def read_sub_sector sub_sector, sector
    link = sub_sector.css("td a")
    
    companies = {}

    if !link[0].nil?
        name = link[0].text + "\n"
        href = link[0]['href']

        name = name.gsub(/\s+/, "").delete('\//\s+/').squeeze('').to_s

        company_doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/#{href}"))

        companies = read_doc company_doc

        4.times {
            companies.shift
        }
        
        companies = read_companies companies, sector, name
    end

    puts "Sector: #{sector}"

    puts "Companies:\n" + companies.to_json

    sector_hash = {
        "#{sector}" => companies
    }

    return sector_hash

end

def read_sub_sectors sub_sectors, sector
    
    pulled_sub_sectors = []

    sub_sectors.each do |sub_sector|
        pulled_sub_sectors << read_sub_sector(sub_sector, sector)
    end

    json_sub_sectors = {
        "#{sector}" => pulled_sub_sectors
    }

    puts "sector ------>  " + json_sub_sectors.to_json
    return sub_sectors
end

def read_sector sector_href
    link = sector_href.css("a")
    name = link.text
    href = link[0]['href']

    name = name.gsub(/\s+/, "").to_s

    sector_doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/#{href}"))

    sub_sectors = read_doc(sector_doc)

    pulled_sub_sectors  = {
        "#{name}" => pulled_sub_sectors
    }

    puts "Name: #{name}\n"

    return read_sub_sectors(sub_sectors, name)
end

def read_sectors sectors
    sectors.shift

    pulled_sectors = []

    sectors.each do |sector|
        pulled_sectors << read_sector(sector)
    end

    stocks = {
        "all" => pulled_sectors
    }

    @file = File.open("stocks.json", 'w') 
    @file.write(stocks.to_json)
end

doc = Nokogiri::HTML(open("https://biz.yahoo.com/p/s_conameu.html"))    

sectors = read_doc doc
read_sectors sectors

puts "Done."