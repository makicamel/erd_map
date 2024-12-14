# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Role < ApplicationRecord
  has_many :role_users, dependent: :destroy
  has_many :users, through: :role_users, class_name: "::User"
end
