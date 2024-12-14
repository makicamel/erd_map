# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class RefundReason < ApplicationRecord
  has_many :refunds, dependent: :restrict_with_error
end
