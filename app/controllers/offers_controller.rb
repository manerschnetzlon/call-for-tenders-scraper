require 'nokogiri'
require 'open-uri'

class OffersController < ApplicationController
  def index
    @offers = Offer.all.order(created_at: :desc)
  end

  def scrape
    words_to_search = ['paris', 'prevoyance', 'complementaire sante']
    words_to_search.each do |word|
      eurolegales_attributes = { url: 'https://www.eurolegales.com',
                                 queries: "/Recherche/France?quoi=#{word}&ta=AppelOffre&page=1",
                                 pagination_selectors: '.pagination > li > a',
                                 pagination_regex: /page=(\d+)/,
                                #  pagination_query: '&page=',
                                 offers_selectors: '.searchResults > table > tbody > tr',
                                 end_date_selectors: 'strong:contains("Remise des offres")' }

      centreofficielles_attributes = { url: 'https://www.centreofficielles.com/',
                                       queries: "recherche_marches_publics_aapc_________1-#{word}.html",
                                       pagination_selectors: '#paginationControl > b > a',
                                       pagination_regex: /_________(\d+)/,
                                      #  pagination_query: '_________1',
                                       offers_selectors: '.resultatOrganismeBasTab2 > p > a',
                                       end_date_selectors: '.resultatOrganismeBasTab4' }

      scrape_site(eurolegales_attributes)
      # scrape_site(centreofficielles_attributes)
    end
    redirect_to offers_path
  end

  private

  def scrape_site(attributes)
    # get html doc with nokogiri
    html_doc = Nokogiri::HTML(open(attributes[:url] + attributes[:queries]).read)

    # raise

    # parse html to build hash
    # find number of pages
    pages = html_doc.search(attributes[:pagination_selectors]).map { |page| page.attribute('href').value }.uniq
    pages_number = pages.empty? ? 1 : pages.map { |page| page.match(attributes[:pagination_regex])[1].to_i }.max
    # TODO MORE THAN 10 PAGES

    # for each page : create a hash for every offer with reference title and link
    all_offers = []
    (1..pages_number).to_a.each do |page|
      # raise
      # url = attributes[:url] + attributes[:queries]
      url = attributes[:url] + attributes[:queries].gsub(attributes[:queries].match(/\d+/)[0], page.to_s)
      html_offers_doc = Nokogiri::HTML(open(url).read)
      offers = html_offers_doc.search(attributes[:offers_selectors])
      unless offers.empty?
        offers.each do |offer|
          td_elements = offer.search('td')
          all_offers << build_offer_hash(td_elements, attributes[:url], attributes[:end_date_selectors])
        end
      end
      # raise

    end
    create_offers_scraped(all_offers.reverse) unless all_offers.empty?
  end

  def build_offer_hash(td_elements, url, end_date_selectors)
    offer_hash = { reference: td_elements.last.text,
                   title: td_elements.first.text,
                   link: url + td_elements.first.search('a').first.attribute('href').value }

    html_offer_doc = Nokogiri::HTML(open(offer_hash[:link]).read)
    html_date = html_offer_doc.at(end_date_selectors)
    unless html_date.nil?
      date = html_date.next.instance_of?(Nokogiri::XML::Element) ? html_date.next_element : html_date.next
      offer_hash[:end_date] = Date.strptime(date.text.match(%r{^(\d+\/\d+\/\d+)})[1], '%d/%m/%Y') unless date.nil?
    end
    offer_hash
  end

  def create_offers_scraped(offers)
    offers.each do |offer|
      next if Offer.exists?(reference: offer[:reference])

      new_offer = Offer.new(reference: offer[:reference], title: offer[:title], link: offer[:link], end_date: offer[:end_date])
      new_offer.save
    end
  end

  # TODO NEXT
  ###########
  # scrap centreofficielle
  # view index offers
  # view show offer
  # edit offer
  # destroy offer => add completed field in db
end
