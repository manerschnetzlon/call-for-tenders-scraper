class Offer < ApplicationRecord
  validates :reference, :title, :link, presence: true
  validates :reference, uniqueness: true
end
