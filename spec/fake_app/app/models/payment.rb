# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Payment < ApplicationRecord
  with_options inverse_of: :payments do
    belongs_to :order, touch: true
    belongs_to :payment_method, -> { with_deleted }
  end
  belongs_to :source, polymorphic: true

  has_many :offsets, -> { offset_payment }, foreign_key: :source_id
  has_many :log_entries, as: :source
  has_many :state_changes, as: :stateful
  has_many :capture_events
  has_many :refunds, inverse_of: :payment
end
