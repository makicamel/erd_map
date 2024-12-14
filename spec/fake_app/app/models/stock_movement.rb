# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StockMovement < ApplicationRecord
  belongs_to :stock_item, inverse_of: :stock_movements
  belongs_to :originator, polymorphic: true
end
