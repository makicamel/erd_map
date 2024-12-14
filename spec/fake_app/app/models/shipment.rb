# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Shipment < ApplicationRecord
  with_options inverse_of: :shipments do
    belongs_to :address
    belongs_to :order, touch: true
  end
  belongs_to :stock_location, -> { with_deleted }

  with_options dependent: :delete_all do
    has_many :adjustments, as: :adjustable
    has_many :inventory_units, inverse_of: :shipment
    has_many :shipping_rates, -> { order(:cost) }
    has_many :state_changes, as: :stateful
  end
  has_many :shipping_methods, through: :shipping_rates
  has_many :variants, through: :inventory_units
  has_one :selected_shipping_rate, -> { where(selected: true).order(:cost) }, class_name: "ShippingRate"
end
