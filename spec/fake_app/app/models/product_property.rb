# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ProductProperty < ApplicationRecord
  with_options inverse_of: :product_properties do
    belongs_to :product, touch: true
    belongs_to :property, touch: true
  end
end
