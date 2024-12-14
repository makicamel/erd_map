# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PromotionRule < ApplicationRecord
  belongs_to :promotion, inverse_of: :promotion_rule_user
end
