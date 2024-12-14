# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Taxon < ApplicationRecord
  belongs_to :taxonomy, inverse_of: :taxons
  has_one :store, through: :taxonomy
  has_many :classifications, -> { order(:position) }, dependent: :destroy_async, inverse_of: :taxon
  has_many :products, through: :classifications
  has_one :icon, as: :viewable, dependent: :destroy # TODO: remove this as this is deprecated

  has_many :menu_items, as: :linked_resource
  has_many :cms_sections, as: :linked_resource

  has_many :prototype_taxons, dependent: :destroy
  has_many :prototypes, through: :prototype_taxons

  has_many :promotion_rule_taxons, dependent: :destroy
  has_many :promotion_rules, through: :promotion_rule_taxons
end
