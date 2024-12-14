# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Variant < ApplicationRecord
  with_options inverse_of: :variant do
    has_many :inventory_units
    has_many :line_items
    has_many :stock_items, dependent: :destroy
  end

  has_many :orders, through: :line_items
  with_options through: :stock_items do
    has_many :stock_locations
    has_many :stock_movements
  end

  has_many :option_value_variants
  has_many :option_values, through: :option_value_variants, dependent: :destroy

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy

  has_many :prices,
           dependent: :destroy,
           inverse_of: :variant

  has_many :wished_items, dependent: :destroy

  has_many :digitals
end
