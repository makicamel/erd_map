# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy
  belongs_to :store, touch: true
  has_one :root, -> { where(parent_id: nil) }, dependent: :destroy
end
