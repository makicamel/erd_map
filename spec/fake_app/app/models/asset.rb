# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Asset < ApplicationRecord
  belongs_to :viewable, polymorphic: true, touch: true
end
