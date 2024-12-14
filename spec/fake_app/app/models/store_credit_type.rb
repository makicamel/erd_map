# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StoreCreditType < ApplicationRecord
  has_many :store_credits, foreign_key: 'type_id'
end
