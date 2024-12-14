# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ShippingMethod < ApplicationRecord
  has_many :shipping_method_categories, dependent: :destroy
  has_many :shipping_categories, through: :shipping_method_categories
  has_many :shipping_rates, inverse_of: :shipping_method
  has_many :shipments, through: :shipping_rates

  has_many :shipping_method_zones,
                                   foreign_key: 'shipping_method_id'
  has_many :zones, through: :shipping_method_zones

  belongs_to :tax_category, -> { with_deleted }, optional: true
end
