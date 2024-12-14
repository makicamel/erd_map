# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ZoneMember < ApplicationRecord
  belongs_to :zone, counter_cache: true, inverse_of: :zone_members
  belongs_to :zoneable, polymorphic: true
end
