# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Calculator < ApplicationRecord
  belongs_to :calculable, polymorphic: true, optional: true, inverse_of: :calculator
end
