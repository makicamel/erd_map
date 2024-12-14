# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class CouponCode < ApplicationRecord
  belongs_to :promotion, touch: true
  belongs_to :order
end
