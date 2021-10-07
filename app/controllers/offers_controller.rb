require 'nokogiri'
require 'open-uri'

class OffersController < ApplicationController
  def scrape
    # EUROLEGALES
    @base_url = 'https://www.eurolegales.com'
    queries = '/Recherche/France?&ta=AppelOffre'
    @url = @base_url + queries
    html_doc = Nokogiri::HTML(open(@url).read)
    @pages_number = get_pages_number(html_doc, '.pagination > li > a', /page=(\d+)/)
    parse_html_doc
  end

  private

  def get_pages_number(html_doc, css_selectors, regex)
    pages = html_doc.search(css_selectors).map { |page| page.attribute('href').value }.uniq
    pages.empty? ? 1 : pages.map { |page| page.match(regex)[1].to_i }.max
    # TODO MORE THAN 10 PAGES
  end

  def parse_html_doc
    all_offers = []
    (1..@pages_number).to_a.each do |page|
      html_doc = Nokogiri::HTML(open(@url + "&page=#{page}").read)
      html_offers = html_doc.search(".searchResults > table > tbody > tr")
      html_offers.each do |offer|
        td_elements = offer.search('td')
        offer_hash = { file: td_elements.last.text,
                       title: td_elements.first.text,
                       link: @base_url + td_elements.first.search("a").first.attribute("href").value }
        all_offers << offer_hash
      end
    end
    raise
  end
end
