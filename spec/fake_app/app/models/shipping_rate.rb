# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ShippingRate < ApplicationRecord
  belongs_to :shipment
  belongs_to :tax_rate, -> { with_deleted }
  belongs_to :shipping_method, -> { with_deleted }, inverse_of: :shipping_rates
end
