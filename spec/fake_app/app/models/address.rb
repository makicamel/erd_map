# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Address < ApplicationRecord
  belongs_to :country
  belongs_to :state, optional: true
  belongs_to :user, optional: true, touch: true

  has_many :shipments, inverse_of: :address
end
