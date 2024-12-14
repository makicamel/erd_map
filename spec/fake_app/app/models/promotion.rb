# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Promotion < ApplicationRecord
  belongs_to :promotion_category, optional: true
  has_many :promotion_rules, autosave: true, dependent: :destroy
  has_many :promotion_actions, autosave: true, dependent: :destroy
  has_many :coupon_codes, -> { order(created_at: :asc) }, dependent: :destroy
  has_many :order_promotions
  has_many :orders, through: :order_promotions
  has_many :store_promotions
  has_many :stores, through: :store_promotions
end
