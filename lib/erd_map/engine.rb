module ErdMap
  class Engine < ::Rails::Engine
    isolate_namespace ErdMap

    initializer "erd_map" do |app|
      ActiveSupport.on_load :after_initialize do
        Rails.application.routes.prepend do
          mount ErdMap::Engine, at: "/erd_map"
        end
      end
    end
  end
end
