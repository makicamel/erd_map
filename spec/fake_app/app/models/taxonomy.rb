# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class Taxonomy < ApplicationRecord
  has_many :taxons, inverse_of: :taxonomy
  has_one :root, -> { where parent_id: nil }, dependent: :destroy
  belongs_to :store
end
