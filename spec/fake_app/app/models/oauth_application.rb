# frozen_string_literal: true

# Models from doorkeeper
# https://github.com/doorkeeper-gem/doorkeeper
class OauthApplication < ApplicationRecord
  has_many :access_grants,
           foreign_key: :application_id,
           dependent: :delete_all,
           class_name: Doorkeeper.config.access_grant_class.to_s

  has_many :access_tokens,
           foreign_key: :application_id,
           dependent: :delete_all,
           class_name: Doorkeeper.config.access_token_class.to_s
  has_many :authorized_tokens,
          -> { where(revoked_at: nil) },
          foreign_key: :application_id,
          class_name: Doorkeeper.config.access_token_class.to_s

  has_many :authorized_applications,
          through: :authorized_tokens,
          source: :application
end
