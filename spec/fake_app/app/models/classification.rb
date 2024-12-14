# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Classification < ApplicationRecord
  with_options inverse_of: :classifications, touch: true do
    belongs_to :product
    belongs_to :taxon
  end
end
