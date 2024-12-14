# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StoreProduct < ApplicationRecord
  belongs_to :store, touch: true
  belongs_to :product, touch: true
end
