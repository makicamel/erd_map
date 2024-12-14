# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class InventoryUnit < ApplicationRecord
  with_options inverse_of: :inventory_units do
    belongs_to :variant, -> { with_deleted }
    belongs_to :order
    belongs_to :shipment, touch: true, optional: true
    has_many :return_items, inverse_of: :inventory_unit
    has_many :return_authorizations, through: :return_items
    belongs_to :line_item
  end

  belongs_to :original_return_item
end
