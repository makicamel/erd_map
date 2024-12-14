# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Refund < ApplicationRecord
  with_options inverse_of: :refunds do
    belongs_to :payment
    belongs_to :reimbursement, optional: true
  end
  belongs_to :reason, foreign_key: :refund_reason_id
  belongs_to :refunder, class_name: "::AdminUser", optional: true

  has_many :log_entries, as: :source
end
