class OffersController < ApplicationController
  before_action :set_offer, only: %i[edit update destroy]

  def index
    @offers = Offer.all.order(created_at: :desc)
  end

  def update
    @offer.update(offer_params)
    redirect_to offers_path
  end

  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy
    redirect_to offers_path
  end

  def scrape
    words_to_search = ['prevoyance', 'complementaire sante']
    words_to_search.each do |word|
      eurolegales = { url: 'https://www.eurolegales.com',
                      queries: "/Recherche/France?quoi=#{word.parameterize(separator: '+')}&ta=AppelOffre&page=1",
                      pagination_selectors: '.pagination > li > a',
                      pagination_regex: /page=(\d+)/,
                      offers_selectors: '.searchResults > table > tbody > tr' }

      centreofficielles = { url: 'https://www.centreofficielles.com/',
                            queries: "recherche_marches_publics_aapc_________1-#{word.parameterize(separator: '_')}.html",
                            pagination_selectors: '#paginationControl > b > a',
                            pagination_regex: /_________(\d+)/,
                            offers_selectors: '.list-organisme > .orga' }

      Scraper.new(eurolegales).call
      Scraper.new(centreofficielles).call
    end
    redirect_to offers_path
  end

  private

  def set_offer
    @offer = Offer.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(:title, :end_date, :publication_date)
  end
end
