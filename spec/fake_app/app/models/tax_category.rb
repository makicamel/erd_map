# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class TaxCategory < ApplicationRecord
  has_many :tax_rates, dependent: :destroy, inverse_of: :tax_category
  has_many :products, dependent: :nullify
  has_many :variants, dependent: :nullify
end
