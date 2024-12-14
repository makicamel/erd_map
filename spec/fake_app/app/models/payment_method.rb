# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PaymentMethod < ApplicationRecord
  has_many :store_payment_methods
  has_many :stores, through: :store_payment_methods

  with_options dependent: :restrict_with_error do
    has_many :payments, inverse_of: :payment_method
    has_many :credit_cards
  end
end
