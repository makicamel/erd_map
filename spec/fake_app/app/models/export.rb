# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Export < ApplicationRecord
  belongs_to :store
  belongs_to :user, class_name: 'AdminUser'
  belongs_to :vendor, -> { with_deleted }, optional: true
end
