# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PaymentCaptureEvent < ApplicationRecord
  belongs_to :payment
end
