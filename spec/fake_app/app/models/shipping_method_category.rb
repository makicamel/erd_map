# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ShippingMethodCategory < ApplicationRecord
  belongs_to :shipping_method
  belongs_to :shipping_category, inverse_of: :shipping_method_categories
end
