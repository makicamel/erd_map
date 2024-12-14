# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class CustomerReturn < ApplicationRecord
  belongs_to :stock_location
  belongs_to :store, inverse_of: :customer_returns

  has_many :reimbursements, inverse_of: :customer_return
  has_many :return_items, inverse_of: :customer_return
  has_many :return_authorizations, through: :return_items
end
