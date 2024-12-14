# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ProductOptionType < ApplicationRecord
  with_options inverse_of: :product_option_types do
    belongs_to :product
    belongs_to :option_type
  end
end
