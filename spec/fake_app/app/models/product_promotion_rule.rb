# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ProductPromotionRule < ApplicationRecord
  belongs_to :product
  belongs_to :promotion_rule
end
