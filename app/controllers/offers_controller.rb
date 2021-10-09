class OffersController < ApplicationController
  def index
    @offers = Offer.all.order(created_at: :desc)
  end

  def scrape
    words_to_search = ["prevoyance", "complementaire sante"]
    words_to_search.each do |word|
      eurolegales = { url: 'https://www.eurolegales.com',
                      queries: "/Recherche/France?quoi=#{word}&ta=AppelOffre&page=1",
                      pagination_selectors: '.pagination > li > a',
                      pagination_regex: /page=(\d+)/,
                      offers_selectors: '.searchResults > table > tbody > tr' }

      centreofficielles = { url: 'https://www.centreofficielles.com',
                            queries: "/recherche_marches_publics_aapc_________1-#{word.parameterize(separator: '_')}.html",
                            pagination_selectors: '#paginationControl > b > a',
                            pagination_regex: /_________(\d+)/,
                            offers_selectors: '.list-organisme > .orga' }

      Scraper.new(eurolegales).call
      Scraper.new(centreofficielles).call
    end
    redirect_to offers_path
  end

  # TODO NEXT
  ###########
  # scrap centreofficielle => OK
  # service => ok
  # view index offers
  # view show offer
  # edit offer
  # destroy offer => add completed field in db
end
