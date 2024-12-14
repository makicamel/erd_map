# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ReturnItem < ApplicationRecord
  with_options inverse_of: :return_items do
    belongs_to :return_authorization
    belongs_to :inventory_unit
    belongs_to :customer_return
    belongs_to :reimbursement
  end
  has_many :exchange_inventory_units,
                                      foreign_key: :original_return_item_id,
                                      inverse_of: :original_return_item
  belongs_to :exchange_variant
  belongs_to :preferred_reimbursement_type
  belongs_to :override_reimbursement_type
end
