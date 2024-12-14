# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class MenuItem < ApplicationRecord
  belongs_to :menu, touch: true
  has_one :icon, as: :viewable, dependent: :destroy
end
