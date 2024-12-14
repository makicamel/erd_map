# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Reimbursement < ApplicationRecord
  with_options inverse_of: :reimbursements do
    belongs_to :order
    belongs_to :customer_return, touch: true, optional: true
  end

  with_options inverse_of: :reimbursement do
    has_many :refunds
    has_many :credits
    has_many :return_items
  end
end
