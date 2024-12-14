# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ShippingMethodZone < ApplicationRecord
  belongs_to :shipping_method, -> { with_deleted }, inverse_of: :shipping_method_zones
  belongs_to :zone, inverse_of: :shipping_method_zones
end
