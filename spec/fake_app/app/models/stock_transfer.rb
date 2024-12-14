# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StockTransfer < ApplicationRecord
  has_many :stock_movements, as: :originator
  belongs_to :source_location, class_name: 'StockLocation', optional: true
  belongs_to :destination_location, class_name: 'StockLocation'
end
