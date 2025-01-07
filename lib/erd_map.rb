require "erd_map/version"
require "erd_map/engine"
require "erd_map/py_call_modules"
require "erd_map/graph"
require "erd_map/graph_renderer"
require "erd_map/map_builder"

module ErdMap
  class << self
    def queue
      @queue
    end

    def queue=(queue)
      @queue = queue
    end

    def py_call_modules
      @py_call_modules
    end

    def py_call_modules=(py_call_modules)
      @py_call_modules = py_call_modules
    end
  end
end
