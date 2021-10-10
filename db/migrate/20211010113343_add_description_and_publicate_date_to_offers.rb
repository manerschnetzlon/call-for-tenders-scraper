class AddDescriptionAndPublicateDateToOffers < ActiveRecord::Migration[6.1]
  def change
    add_column :offers, :description, :text
    add_column :offers, :publication_date, :date
  end
end
