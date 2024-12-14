# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class DataFeed < ApplicationRecord
  belongs_to :store, foreign_key: 'store_id'
end
