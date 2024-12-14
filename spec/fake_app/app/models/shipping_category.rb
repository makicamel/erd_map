# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ShippingCategory < ApplicationRecord
  with_options inverse_of: :shipping_category do
    has_many :products
    has_many :shipping_method_categories
  end
  has_many :shipping_methods, through: :shipping_method_categories
end
