# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Prototype < ApplicationRecord
  has_many :property_prototypes
  has_many :properties, through: :property_prototypes

  has_many :option_type_prototypes
  has_many :option_types, through: :option_type_prototypes

  has_many :prototype_taxons
  has_many :taxons, through: :prototype_taxons
end
