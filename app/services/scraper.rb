require 'nokogiri'
require 'open-uri'

class Scraper
  def initialize(attributes = {})
    @url = attributes[:url]
    @queries = attributes[:queries]
    @pagination_selectors = attributes[:pagination_selectors]
    @pagination_regex = attributes[:pagination_regex]
    @offers_selectors = attributes[:offers_selectors]
  end

  def call
    pages_number = self.find_pages_number
    (1..pages_number).to_a.each do |page|
      url = @url + @queries.gsub(@queries.match(/\d+/)[0], page.to_s)
      html_offers_doc = Nokogiri::HTML(open(url).read)
      offers = html_offers_doc.search(@offers_selectors)
      offers.each do |offer|
        create_eurolegales_offer(offer) if @url == 'https://www.eurolegales.com'
        create_centreofficielles_offer(offer) if @url == 'https://www.centreofficielles.com/'
      end
    end
  end

  def find_pages_number
    html_doc = Nokogiri::HTML(open(@url + @queries).read)
    pages = html_doc.search(@pagination_selectors).map { |page| page.attribute('href').value }.uniq
    max_pages_number = pages.empty? ? 1 : pages.map { |page| page.match(@pagination_regex)[1].to_i }.max
    current_page = @queries.match(/\d+/)[0].to_i
    return current_page if current_page >= max_pages_number

    @queries = @queries.gsub(current_page.to_s, max_pages_number.to_s)
    self.find_pages_number
  end

  def create_eurolegales_offer(offer)
    td_elements = offer.search('td')
    offer_hash = { reference: td_elements.last.text,
                   title: td_elements.first.text,
                   link: "https://www.eurolegales.com#{td_elements.first.search('a').first.attribute('href').value}",
                   publication_date: Date.strptime(td_elements[1].text, '%d/%m/%y') }

    html_doc = Nokogiri::HTML(open(offer_hash[:link]).read)
    html_description = html_doc.at('.description').inner_html
    offer_hash[:description] = html_description
    html_end_date = html_doc.at('strong:contains("Remise")')
    unless html_end_date.nil?
      date = html_end_date.next.instance_of?(Nokogiri::XML::Element) ? html_end_date.next_element : html_end_date.next
      offer_hash[:end_date] = Date.strptime(date.text.match(%r{^(\d+\/\d+\/\d+)})[1], '%d/%m/%y') unless date.nil?
    end
    create_offer(offer_hash)
  end

  def create_centreofficielles_offer(offer)
    link = offer.search('.resultatOrganismeBasTab2 > p > a').first.attribute('href').value
    date = offer.search('.resultatOrganismeBas').text.match(%r{\d+\/\d+\/\d+})[0]
    reference = link.match(/_(\d+_\d+).html/)[1]
    offer_hash = { reference: reference,
                   title: offer.search('.resultatOrganismeMilieu > p').text,
                   link: "https://www.centreofficielles.com/#{link}",
                   end_date: Date.strptime(date, '%d/%m/%Y') }
    html_doc = Nokogiri::HTML(open(offer_hash[:link]).read)
    html_description = html_doc.at('.texte').inner_html
    offer_hash[:description] = html_description
    html_publication_date = html_doc.at(':contains("Date d\'envoi du présent avis"):not(:has(:contains("Date d\'envoi du présent avis")))')
    offer_hash[:publication_date] = html_publication_date.next.text.to_date unless html_publication_date.nil?
    create_offer(offer_hash)
  end

  def create_offer(offer_hash)
    return if Offer.exists?(reference: offer_hash[:reference])

    Offer.create(reference: offer_hash[:reference],
                 title: offer_hash[:title],
                 link: offer_hash[:link],
                 description: offer_hash[:description],
                 publication_date: offer_hash[:publication_date],
                 end_date: offer_hash[:end_date])
  end
end
