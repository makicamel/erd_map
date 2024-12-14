# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class PropertyPrototype < ApplicationRecord
  belongs_to :prototype
  belongs_to :property
end
