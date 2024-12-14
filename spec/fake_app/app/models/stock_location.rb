# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StockLocation < ApplicationRecord
  has_many :shipments
  has_many :stock_items, dependent: :delete_all, inverse_of: :stock_location
  has_many :variants, through: :stock_items
  has_many :stock_movements, through: :stock_items

  belongs_to :state, optional: true
  belongs_to :country
end
