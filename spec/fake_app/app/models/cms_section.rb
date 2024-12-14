# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class CmsSection < ApplicationRecord
  belongs_to :cms_page, touch: true
  has_one :image_one, dependent: :destroy, as: :viewable
  has_one :image_two, dependent: :destroy, as: :viewable
  has_one :image_three, dependent: :destroy, as: :viewable
end
