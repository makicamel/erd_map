# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Country < ApplicationRecord
  has_many :addresses, dependent: :restrict_with_error
  has_many :states,
           -> { order name: :asc },
           inverse_of: :country,
           dependent: :destroy
  has_many :zone_members,
           -> { where(zoneable_type: 'Country') },
           dependent: :destroy,
           foreign_key: :zoneable_id
  has_many :zones, through: :zone_members
end
