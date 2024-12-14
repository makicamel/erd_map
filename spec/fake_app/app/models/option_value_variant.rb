# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class OptionValueVariant < ApplicationRecord
  belongs_to :option_value
  belongs_to :variant, touch: true
end
