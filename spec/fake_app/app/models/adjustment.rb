# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Adjustment < ApplicationRecord
  with_options polymorphic: true do
    belongs_to :adjustable, touch: true
    belongs_to :source
  end
  belongs_to :order, inverse_of: :all_adjustments
  belongs_to :promotion_action, foreign_key: :source_id, optional: true # created only for has_free_shipping?
end
