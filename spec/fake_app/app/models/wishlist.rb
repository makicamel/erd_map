# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Wishlist < ApplicationRecord
  belongs_to :user, class_name: "::User", touch: true
  belongs_to :store

  has_many :wished_items, dependent: :destroy
  has_many :variants, through: :wished_items, source: :variant
  has_many :products, -> { distinct }, through: :variants, source: :product
end
