# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class OptionTypePrototype < ApplicationRecord
  belongs_to :option_type
  belongs_to :prototype
end
