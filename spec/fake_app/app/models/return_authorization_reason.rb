# frozen_string_literal: true

# Models from spree
# https://github.com/spree/spree
class ReturnAuthorizationReason < ApplicationRecord
  has_many :return_authorizations, dependent: :restrict_with_error
end
