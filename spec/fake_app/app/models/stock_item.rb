# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StockItem < ApplicationRecord
  with_options inverse_of: :stock_items do
    belongs_to :stock_location
    belongs_to :variant, -> { with_deleted }
  end
  has_many :stock_movements, inverse_of: :stock_item
end
