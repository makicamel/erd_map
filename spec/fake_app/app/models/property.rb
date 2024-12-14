# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Property < ApplicationRecord
  has_many :property_prototypes
  has_many :prototypes, through: :property_prototypes

  has_many :product_properties, dependent: :delete_all, inverse_of: :property
  has_many :products, through: :product_properties
end
