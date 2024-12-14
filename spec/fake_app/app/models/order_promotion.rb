# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class OrderPromotion < ApplicationRecord
  belongs_to :order
  belongs_to :promotion
end
