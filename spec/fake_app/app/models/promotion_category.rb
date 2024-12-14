# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PromotionCategory < ApplicationRecord
  has_many :promotions
end
