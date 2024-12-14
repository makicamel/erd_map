# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class WishedItem < ApplicationRecord
  belongs_to :variant
  belongs_to :wishlist

  has_one :product, through: :variant
end
