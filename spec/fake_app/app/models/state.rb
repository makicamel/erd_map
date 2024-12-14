# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class State < ApplicationRecord
  belongs_to :country
  has_many :addresses, dependent: :restrict_with_error

  has_many :zone_members,
           -> { where(zoneable_type: 'State') },
           dependent: :destroy,
           foreign_key: :zoneable_id

  has_many :zones, through: :zone_members
end
