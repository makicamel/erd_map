# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PaymentSource < ApplicationRecord
  belongs_to :payment_method
  belongs_to :user, optional: true
end
