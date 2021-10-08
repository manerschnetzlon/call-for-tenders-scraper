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
                                 queries: "/Recherche/France?quoi=#{word}&ta=AppelOffre",
                                 pagination_selectors: '.pagination > li > a',
                                 pagination_regex: /page=(\d+)/,
                                 pagination_query: '&page=',
                                 offers_selectors: '.searchResults > table > tbody > tr',
                                 end_date_selectors: 'strong:contains("Remise des offres")' }

      scrape_site(eurolegales_attributes)
    end

    # eurolegales_attributes = { url: 'https://www.eurolegales.com', queries: '/Recherche/France?&ta=AppelOffre', pagination_selectors: '.pagination > li > a', pagination_regex: /page=(\d+)/, pagination_query: , offers_selectors: , end_date_selectors: }
    # scrape_site(eurolegales_attributes)

    # centreofficielles_attributes = { }
    # scrape_site(centreofficielles_attributes)
    redirect_to offers_path
  end

  private

  def scrape_site(attributes)
    # get html doc with nokogiri
    html_doc = Nokogiri::HTML(open(attributes[:url] + attributes[:queries]).read)

    # parse html to build hash
    # find number of pages
    pages = html_doc.search(attributes[:pagination_selectors]).map { |page| page.attribute("href").value }.uniq
    pages_number = pages.empty? ? 1 : pages.map { |page| page.match(attributes[:pagination_regex])[1].to_i }.max
    # TODO MORE THAN 10 PAGES

    # for each page : create a hash for every offer with reference title and link
    all_offers = []
    (1..pages_number).to_a.each do |page|
      url = attributes[:url] + attributes[:queries] + attributes[:pagination_query] + page.to_s
      html_offers_doc = Nokogiri::HTML(open(url).read)
      offers = html_offers_doc.search(attributes[:offers_selectors])
      offers.each do |offer|
        td_elements = offer.search('td')
        offer_hash = { reference: td_elements.last.text,
                       title: td_elements.first.text,
                       link: attributes[:url] + td_elements.first.search('a').first.attribute('href').value }

        # for each offer : add end_date to the hash
        html_offer_doc = Nokogiri::HTML(open(offer_hash[:link]).read)
        date = html_offer_doc.at(attributes[:end_date_selectors])
        unless date.nil?
          unless date.next.nil?
            date_element = if date.next.instance_of?(Nokogiri::XML::Element)
                             date.next_element
                           else
                             date.next
                           end
            offer_hash[:end_date] = Date.strptime(date_element.text.match(/^(\d+\/\d+\/\d+)/)[1], "%d/%m/%y")
          end
          # raise
        end

        # unless date.nil?
        #   break if date.next.nil?
        #   # return if date.next.nil?
        #   date_element = if date.next.instance_of?(Nokogiri::XML::Text)
        #                    date.next
        #                  elsif date.next.instance_of?(Nokogiri::XML::Element)
        #                    date.next_element
        #                  end

        #   offer[:end_date] = Date.strptime(date_element.text.match(/^(\d+\/\d+\/\d+)/)[1], "%d/%m/%y")
        # end

        all_offers << offer_hash
      end
    end

    # create Offer from the hash
    all_offers.reverse.each do |offer|
      next if Offer.exists?(reference: offer[:reference])

      new_offer = Offer.new(reference: offer[:reference], title: offer[:title], link: offer[:link], end_date: offer[:end_date])
    #   new_offer.end_date = offer[:end_date] unless offer[:end_date].nil?
      new_offer.save
    end
  end


  # TODO NEXT
  ###########
  # view index offers
  # view show offer
  # edit offer
  # destroy offer => add completed field in db

  # def scrape
  #   # EUROLEGALES
  #   @base_url = 'https://www.eurolegales.com'
  #   queries = '/Recherche/France?&ta=AppelOffre'
  #   @url = @base_url + queries
  #   html_doc = Nokogiri::HTML(open(@url).read)
  #   @pages_number = scrape_pages_number(html_doc, '.pagination > li > a', /page=(\d+)/)
  #   parse_html_doc
  # end

  # private

  # def scrape_pages_number(html_doc, css_selectors, regex)
  #   pages = html_doc.search(css_selectors).map { |page| page.attribute('href').value }.uniq
  #   pages.empty? ? 1 : pages.map { |page| page.match(regex)[1].to_i }.max
  #   # TODO MORE THAN 10 PAGES
  # end

  # def parse_html_doc
  #   all_offers = []
  #   (1..@pages_number).to_a.each do |page|
  #     html_offers_doc = Nokogiri::HTML(open(@url + '&page=#{page}').read)
  #     offers = html_offers_doc.search('.searchResults > table > tbody > tr')
  #     offers.each do |offer|
  #       td_elements = offer.search('td')
  #       offer_hash = { file: td_elements.last.text,
  #                      title: td_elements.first.text,
  #                      link: @base_url + td_elements.first.search('a').first.attribute('href').value }

  #       get_end_date(offer)
  #       all_offers << offer_hash
  #       raise
  #     end
  #   end
  # end

  # def get_end_date(offer)
  #   html_offer_notice_doc = Nokogiri::HTML(open(offer[:link]).read)
  #   date = html_offer_notice_doc.at('strong:contains("Remise des offres")')
  #   unless date.nil?
  #     element = if date.next.instance_of?(Nokogiri::XML::Text)
  #                 date.next
  #               elsif date.next.instance_of?(Nokogiri::XML::Element)
  #                 date.next_element
  #               else
  #                 next
  #               end

  #     offer[:date] = Date.strptime(element.text.match(/^(\d+\/\d+\/\d+)/)[1], "%d/%m/%y")
  #   end
  # end

end
