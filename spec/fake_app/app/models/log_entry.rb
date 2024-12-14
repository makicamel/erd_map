# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class LogEntry < ApplicationRecord
  belongs_to :source, polymorphic: true
end
