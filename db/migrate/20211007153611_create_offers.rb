class CreateOffers < ActiveRecord::Migration[6.1]
  def change
    create_table :offers do |t|
      t.string :reference
      t.string :title
      t.string :link
      t.date :end_date

      t.timestamps
    end
  end
end
