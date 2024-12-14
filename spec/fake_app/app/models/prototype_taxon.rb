# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PrototypeTaxon < ApplicationRecord
  belongs_to :taxon
  belongs_to :prototype
end
