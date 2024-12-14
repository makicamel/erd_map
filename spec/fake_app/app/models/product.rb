# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Product < ApplicationRecord
  has_many :product_option_types, -> { order(:position) }, dependent: :destroy, inverse_of: :product
  has_many :option_types, through: :product_option_types
  has_many :product_properties, dependent: :destroy, inverse_of: :product
  has_many :properties, through: :product_properties

  has_many :menu_items, as: :linked_resource

  has_many :classifications, -> { order(created_at: :asc) }, dependent: :delete_all, inverse_of: :product
  has_many :taxons, through: :classifications, before_remove: :remove_taxon
  has_many :taxonomies, through: :taxons

  has_many :product_promotion_rules
  has_many :promotion_rules, through: :product_promotion_rules

  has_many :promotions, through: :promotion_rules

  has_many :possible_promotions, -> { advertised.active }, through: :promotion_rules,
                                                           source: :promotion

  belongs_to :tax_category
  belongs_to :shipping_category, inverse_of: :products

  has_one :master,
          -> { where is_master: true },
          inverse_of: :product,
          class_name: 'Variant'

  has_many :variants,
           -> { where(is_master: false).order(:position) },
           inverse_of: :product,
           class_name: 'Variant'

  has_many :variants_including_master,
           -> { order(:position) },
           inverse_of: :product,
           class_name: 'Variant',
           dependent: :destroy

  has_many :prices, -> { order('spree_variants.position, spree_variants.id, currency') }, through: :variants

  has_many :stock_items, through: :variants_including_master

  has_many :line_items, through: :variants_including_master
  has_many :orders, through: :line_items

  has_many :variant_images, -> { order(:position) }, source: :images, through: :variants_including_master
  has_many :variant_images_without_master, -> { order(:position) }, source: :images, through: :variants

  has_many :option_value_variants, through: :variants
  has_many :option_values, through: :variants

  has_many :prices_including_master, -> { non_zero }, through: :variants_including_master, source: :prices

  has_many :store_products
  has_many :stores, through: :store_products
  has_many :digitals, through: :variants_including_master
end
