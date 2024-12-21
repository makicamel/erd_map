# frozen_string_literal: true

require "pycall"

module ErdMap
  class PyCallModules
    def initialize
      @nx = PyCall.import_module("networkx")
      @bokeh_io = PyCall.import_module("bokeh.io")
      @bokeh_models = PyCall.import_module("bokeh.models")
      @bokeh_plotting = PyCall.import_module("bokeh.plotting")
      @bokeh_palettes = PyCall.import_module("bokeh.palettes")
    end

    def imported_modules
      [@nx, @bokeh_io, @bokeh_models, @bokeh_plotting, @bokeh_palettes]
    end
  end
end
