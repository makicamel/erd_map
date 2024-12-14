# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Store < ApplicationRecord
  has_many :orders
  has_many :line_items, through: :orders
  has_many :shipments, through: :orders
  has_many :payments, through: :orders
  has_many :return_authorizations, through: :orders

  has_many :store_payment_methods
  has_many :payment_methods, through: :store_payment_methods

  has_many :cms_pages
  has_many :cms_sections, through: :cms_pages

  has_many :menus
  has_many :menu_items, through: :menus

  has_many :store_products
  has_many :products, through: :store_products
  has_many :product_properties, through: :products
  has_many :variants, through: :products, source: :variants_including_master
  has_many :stock_items, through: :variants
  has_many :inventory_units, through: :variants
  has_many :option_value_variants, through: :variants
  has_many :customer_returns, inverse_of: :store

  has_many :store_credits
  has_many :store_credit_events, through: :store_credits

  has_many :taxonomies
  has_many :taxons, through: :taxonomies

  has_many :store_promotions
  has_many :promotions, through: :store_promotions

  has_many :wishlists

  has_many :data_feeds

  belongs_to :default_country
  belongs_to :checkout_zone

  has_one :logo, dependent: :destroy, as: :viewable
  has_one :mailer_logo, dependent: :destroy, as: :viewable
  has_one :favicon_image, dependent: :destroy, as: :viewable
end
