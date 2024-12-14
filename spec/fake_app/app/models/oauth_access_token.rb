# frozen_string_literal: true

# Models from doorkeeper
# https://github.com/doorkeeper-gem/doorkeeper
class OauthAccessToken < ApplicationRecord
  belongs_to :application, class_name: Doorkeeper.config.application_class.to_s,
                           inverse_of: :access_tokens,
                           optional: true
end
