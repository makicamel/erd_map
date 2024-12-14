# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class CmsPage < ApplicationRecord
  belongs_to :store, touch: true

  has_many :cms_sections
  has_many :menu_items, as: :linked_resource
end
