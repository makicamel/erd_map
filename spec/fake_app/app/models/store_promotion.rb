# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StorePromotion < ApplicationRecord
  belongs_to :store, touch: true
  belongs_to :promotion, touch: true
end
