# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class OptionType < ApplicationRecord
  with_options dependent: :destroy, inverse_of: :option_type do
    has_many :option_values, -> { order(:position) }
    has_many :product_option_types
  end
  has_many :products, through: :product_option_types
  has_many :option_type_prototypes
  has_many :prototypes, through: :option_type_prototypes
end
