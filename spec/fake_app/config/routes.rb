# frozen_string_literal: true

ErdMapTestApp::Application.routes.draw do
  mount ErdMap::Engine => "/erd_map"
end
