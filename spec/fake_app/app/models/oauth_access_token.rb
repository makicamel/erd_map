# frozen_string_literal: true

# Models from doorkeeper
# https://github.com/doorkeeper-gem/doorkeeper
class OauthAccessToken < ApplicationRecord
  belongs_to :application, inverse_of: :access_tokens,
                           optional: true
end
