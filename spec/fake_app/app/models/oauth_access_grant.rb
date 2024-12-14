# frozen_string_literal: true

# Models from doorkeeper
# https://github.com/doorkeeper-gem/doorkeeper
class OauthAccessGrant < ApplicationRecord
  belongs_to :application, optional: true,
                           inverse_of: :access_grants
end
