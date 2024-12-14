# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Price < ApplicationRecord
  belongs_to :variant, -> { with_deleted }, inverse_of: :prices, touch: true
end
