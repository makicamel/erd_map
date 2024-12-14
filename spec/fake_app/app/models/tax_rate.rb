# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class TaxRate < ApplicationRecord
  with_options inverse_of: :tax_rates do
    belongs_to :zone, optional: true
    belongs_to :tax_category
  end
end
