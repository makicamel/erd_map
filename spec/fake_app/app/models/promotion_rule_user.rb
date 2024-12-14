# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PromotionRuleUser < ApplicationRecord
  belongs_to :promotion_rule
  belongs_to :user, class_name: "::User"
end
