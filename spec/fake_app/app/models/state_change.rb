# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class StateChange < ApplicationRecord
  belongs_to :user, class_name: "::User", optional: true
  belongs_to :stateful, polymorphic: true
end
