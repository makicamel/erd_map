# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class RoleUser < ApplicationRecord
  belongs_to :role
  belongs_to :user, class_name: '::AdminUser'
end
