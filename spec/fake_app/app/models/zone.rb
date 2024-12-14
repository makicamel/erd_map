# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Zone < ApplicationRecord
  with_options dependent: :destroy, inverse_of: :zone do
    has_many :zone_members
    has_many :tax_rates
  end
  with_options through: :zone_members, source: :zoneable do
    has_many :countries, source_type: 'Country'
    has_many :states, source_type: 'State'
  end

  has_many :shipping_method_zones
  has_many :shipping_methods, through: :shipping_method_zones
end
