# frozen_string_literal: true

module ErdMap
  class MapBuilder
    def execute
      import_modules
      @graph = ErdMap::Graph.new
      @graph_renderer = ErdMap::GraphRenderer.new(@graph)
      save(build_layout)
    end

    private

    attr_reader :bokeh_io, :bokeh_models, :bokeh_plotting
    attr_reader :graph, :graph_renderer

    def import_modules
      import_modules = ErdMap.py_call_modules.imported_modules
      @bokeh_io = import_modules[:bokeh_io]
      @bokeh_models = import_modules[:bokeh_models]
      @bokeh_plotting = import_modules[:bokeh_plotting]
    end

    def build_layout
      plot = Plot.new(graph)
      plot.renderers.append(graph_renderer.rect_renderer)
      plot.renderers.append(graph_renderer.circle_renderer)
      plot.add_layout(default_label)
      plot.add_layout(cardinality_label_set)
      # plot.add_layout(title_label)
      # plot.add_layout(columns_label)
      bokeh_io.curdoc.js_on_event("document_ready", setup_graph_manager(plot))
      graph_renderer.node_renderer.data_source.selected.js_on_change("indices", toggle_tapped)

      bokeh_models.Column.new(
        children: [
          bokeh_models.Row.new(
            children: [
              plot.button_set[:left_spacer],
              graph_renderer.selecting_node_label,
              plot.button_set[:search_box],
              plot.button_set[:zoom_mode_toggle],
              plot.button_set[:tap_mode_toggle],
              plot.button_set[:display_title_mode_toggle],
              plot.button_set[:zoom_in_button],
              plot.button_set[:zoom_out_button],
              plot.button_set[:right_spacer],
            ],
            sizing_mode: "stretch_width",
          ),
          plot.plot,
        ],
        sizing_mode: "stretch_both",
      )
    end

    def save(layout)
      tmp_dir = Rails.root.join("tmp", "erd_map")
      FileUtils.makedirs(tmp_dir) unless Dir.exist?(tmp_dir)
      output_path = File.join(tmp_dir, "result.html")

      bokeh_io.output_file(output_path)
      bokeh_io.save(layout)
      puts output_path
    end

    def setup_graph_manager(plot)
      bokeh_models.CustomJS.new(
        args: graph_renderer.js_args(plot),
        code: <<~JS
          #{graph_manager}
          window.graphManager = new GraphManager({
            graphRenderer,
            rectRenderer,
            circleRenderer,
            layoutProvider,
            connectionsData,
            layoutsByChunkData,
            chunkedNodesData,
            nodeWithCommunityIndexData,
            selectingNodeLabel,
            searchBox,
            zoomModeToggle,
            tapModeToggle,
            displayTitleModeToggle,
            windowObj: window,
          })
        JS
      )
    end

    def toggle_tapped
      bokeh_models.CustomJS.new(
        code: <<~JS
          window.graphManager.cbObj = cb_obj
          window.graphManager.toggleTapped()
        JS
      )
    end

    def default_label
      bokeh_models.LabelSet.new(
        x: "x",
        y: "y",
        text: "index",
        source: graph_renderer.node_renderer.data_source,
        text_font_size: "12pt",
        text_color: { field: "text_color" },
        text_outline_color: { field: "text_outline_color" },
        text_align: "center",
        text_baseline: "middle",
        text_alpha: { field: "alpha" },
      )
    end


    def title_label
      bokeh_models.LabelSet.new(
        x: "x",
        y: "y",
        text: { field: "title_label" },
        source: graph_renderer.node_renderer.data_source,
        text_font_size: "10pt",
        text_font_style: "bold",
        text_color: { field: "text_color" },
        text_outline_color: { field: "text_outline_color" },
        text_align: "center",
        text_baseline: "middle",
        text_alpha: { field: "alpha" },
      )
    end

    def columns_label
      bokeh_models.LabelSet.new(
        x: "x",
        y: "y",
        text: { field: "columns_label" },
        source: graph_renderer.node_renderer.data_source,
        text_font_size: "10pt",
        text_font_style: "normal",
        text_color: { field: "text_color" },
        text_outline_color: { field: "text_outline_color" },
        text_align: "center",
        text_baseline: "middle",
        text_alpha: { field: "alpha" },
      )
    end

    def cardinality_label_set
      @cardinality_label_set ||= bokeh_models.LabelSet.new(
        x: "x",
        y: "y",
        text: "text",
        source: graph_renderer.cardinality_data_source,
        text_font_size: "12pt",
        text_color: "text_color",
        text_alpha: { field: "alpha" },
      )
    end

    def graph_manager
      @graph_manager ||= File.read(__dir__ + "/graph_manager.js")
    end

    class << self
      def build
        Rails.logger.info "build start"
        new.execute
        Rails.logger.info "build completed"
      end
    end
  end
end
