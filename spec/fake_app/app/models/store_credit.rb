# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StoreCredit < ApplicationRecord
  belongs_to :user, class_name: "::User", foreign_key: 'user_id'
  belongs_to :category, optional: true
  belongs_to :created_by, class_name: "::AdminUser", foreign_key: 'created_by_id', optional: true
  belongs_to :credit_type, foreign_key: 'type_id', optional: true
  belongs_to :store

  has_many :store_credit_events
  has_many :payments, as: :source
  has_many :orders, through: :payments
end
