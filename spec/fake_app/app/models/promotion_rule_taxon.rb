# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PromotionRuleTaxon < ApplicationRecord
  belongs_to :promotion_rule
  belongs_to :taxon
end
