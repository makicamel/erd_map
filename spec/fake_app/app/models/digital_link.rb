# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class DigitalLink < ApplicationRecord
  belongs_to :digital
  belongs_to :line_item
end
