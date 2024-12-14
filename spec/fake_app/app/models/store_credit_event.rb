# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StoreCreditEvent < ApplicationRecord
  belongs_to :store_credit
  belongs_to :originator, polymorphic: true
end
