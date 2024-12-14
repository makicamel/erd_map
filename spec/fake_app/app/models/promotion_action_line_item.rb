# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PromotionActionLineItem < ApplicationRecord
  belongs_to :promotion_action
  belongs_to :variant
end
