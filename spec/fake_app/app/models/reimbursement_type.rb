# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ReimbursementType < ApplicationRecord
  has_many :return_items
end
