# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ReturnAuthorization < ApplicationRecord
  belongs_to :order, inverse_of: :return_authorizations

  has_many :return_items, inverse_of: :return_authorization, dependent: :destroy
  with_options through: :return_items do
    has_many :inventory_units
    has_many :customer_returns
  end

  belongs_to :stock_location
  belongs_to :reason, foreign_key: :return_authorization_reason_id
end
