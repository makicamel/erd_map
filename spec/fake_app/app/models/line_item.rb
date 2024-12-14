# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class LineItem < ApplicationRecord
  with_options inverse_of: :line_items do
    belongs_to :order, touch: true
    belongs_to :variant, -> { with_deleted }
  end
  belongs_to :tax_category, -> { with_deleted }

  has_one :product, -> { with_deleted }, through: :variant

  has_many :adjustments, as: :adjustable, dependent: :destroy
  has_many :inventory_units, inverse_of: :line_item
  has_many :digital_links, dependent: :destroy
end
