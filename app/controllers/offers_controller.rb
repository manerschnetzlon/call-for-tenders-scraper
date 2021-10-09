require 'nokogiri'
require 'open-uri'

class OffersController < ApplicationController
  def index
    @offers = Offer.all.order(created_at: :desc)
  end

  def scrape
    words_to_search = ['prevoyance', 'complementaire sante']
    words_to_search.each do |word|
      eurolegales_attributes = { url: 'https://www.eurolegales.com',
                                 queries: "/Recherche/France?quoi=#{word}&ta=AppelOffre&page=1",
                                 pagination_selectors: '.pagination > li > a',
                                 pagination_regex: /page=(\d+)/,
                                 offers_selectors: '.searchResults > table > tbody > tr' }

      centreofficielles_attributes = { url: 'https://www.centreofficielles.com',
                                       queries: "/recherche_marches_publics_aapc_________1-#{word.parameterize(separator: '_')}.html",
                                       pagination_selectors: '#paginationControl > b > a',
                                       pagination_regex: /_________(\d+)/,
                                       offers_selectors: '.list-organisme > .orga' }

      scrape_site(eurolegales_attributes)
    end
    redirect_to offers_path
  end

  private

  def scrape_site(attributes)
    html_doc = Nokogiri::HTML(open(attributes[:url] + attributes[:queries]).read)

    pages = html_doc.search(attributes[:pagination_selectors]).map { |page| page.attribute('href').value }.uniq
    pages_number = pages.empty? ? 1 : pages.map { |page| page.match(attributes[:pagination_regex])[1].to_i }.max
    # TODO MORE THAN 10 PAGES

    (1..pages_number).to_a.each do |page|
      url = attributes[:url] + attributes[:queries].gsub(attributes[:queries].match(/\d+/)[0], page.to_s)
      html_offers_doc = Nokogiri::HTML(open(url).read)
      offers = html_offers_doc.search(attributes[:offers_selectors])

      offers.each do |offer|
        create_eurolegales_offer(offer) if attributes[:url] == 'https://www.eurolegales.com'
        create_centreofficielles_offer(offer) if attributes[:url] == 'https://www.centreofficielles.com'
      end
    end
  end

  def create_eurolegales_offer(offer)
    td_elements = offer.search('td')
    offer_hash = { reference: td_elements.last.text,
                   title: td_elements.first.text,
                   link: "https://www.eurolegales.com#{td_elements.first.search('a').first.attribute('href').value}" }

    html_date = Nokogiri::HTML(open(offer_hash[:link]).read).at('strong:contains("Remise")')
    unless html_date.nil?
      date = html_date.next.instance_of?(Nokogiri::XML::Element) ? html_date.next_element : html_date.next
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
                   link: "https://www.centreofficielles.com#{link}",
                   end_date: Date.strptime(date, '%d/%m/%Y') }
    create_offer(offer_hash)
  end

  def create_offer(offer_hash)
    return if Offer.exists?(reference: offer_hash[:reference])

    Offer.create(reference: offer_hash[:reference],
                 title: offer_hash[:title],
                 link: offer_hash[:link],
                 end_date: offer_hash[:end_date])
  end

  # TODO NEXT
  ###########
  # scrap centreofficielle
  # view index offers
  # view show offer
  # edit offer
  # destroy offer => add completed field in db
end
