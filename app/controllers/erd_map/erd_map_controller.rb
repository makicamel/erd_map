# frozen_string_literal: true

module ErdMap
  class ErdMapController < ApplicationController
    def index
      Rails.application.eager_load!
      ErdMap.queue.push(-> { ErdMap::MapBuilder.build })

      render json: { message: "ok." }
    end
  end
end
