# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class TaxonRule < ApplicationRecord
  belongs_to :taxon, inverse_of: :taxon_rules, touch: true
end
