# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class CreditCard < ApplicationRecord
  belongs_to :payment_method
  belongs_to :user, foreign_key: 'user_id',
                    optional: true
  has_many :payments, as: :source
end
