# frozen_string_literal: true

ErdMap::Engine.routes.draw do
  root to: "erd_map#index"
  put "/", to: "erd_map#update"
end
