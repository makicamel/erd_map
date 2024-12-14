# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Digital < ApplicationRecord
  belongs_to :variant
  has_many :digital_links, dependent: :destroy
end
