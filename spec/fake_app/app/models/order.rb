# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Order < ApplicationRecord
  belongs_to :user, class_name: "::User", optional: true
  belongs_to :created_by, class_name: "::AdminUser", optional: true
  belongs_to :approver, class_name: "::AdminUser", optional: true
  belongs_to :canceler, class_name: "::AdminUser", optional: true

  belongs_to :bill_address, foreign_key: :bill_address_id,
                            optional: true, dependent: :destroy
  belongs_to :ship_address, foreign_key: :ship_address_id,
                            optional: true, dependent: :destroy
  belongs_to :store

  with_options dependent: :destroy do
    has_many :state_changes, as: :stateful
    has_many :line_items, -> { order(:created_at) }, inverse_of: :order
    has_many :payments
    has_many :return_authorizations, inverse_of: :order
    has_many :adjustments, -> { order(:created_at) }, as: :adjustable
  end
  has_many :reimbursements, inverse_of: :order
  has_many :line_item_adjustments, through: :line_items, source: :adjustments
  has_many :inventory_units, inverse_of: :order
  has_many :return_items, through: :inventory_units
  has_many :variants, through: :line_items
  has_many :products, through: :variants
  has_many :refunds, through: :payments
  has_many :all_adjustments,
           foreign_key: :order_id,
           dependent: :destroy,
           inverse_of: :order

  has_many :order_promotions
  has_many :promotions, through: :order_promotions

  has_many :shipments, dependent: :destroy, inverse_of: :order
  has_many :shipment_adjustments, through: :shipments, source: :adjustments
end
