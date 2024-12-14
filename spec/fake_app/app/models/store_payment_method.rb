# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StorePaymentMethod < ApplicationRecord
  belongs_to :store, touch: true
  belongs_to :payment_method, touch: true
end
