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
      padding_ratio = 0.1
      x_min, x_max, y_min, y_max = graph.initial_layout.values.transpose.map(&:minmax).flatten
      x_padding, y_padding = [(x_max - x_min) * padding_ratio, (y_max - y_min) * padding_ratio]

      zoom_mode_toggle = bokeh_models.Button.new(label: "Wheel mode: fix", button_type: "default").tap do |button|
        button.js_on_click(custom_js("toggleZoomMode", zoom_mode_toggle: button))
      end
      tap_mode_toggle = bokeh_models.Button.new(label: "Tap mode: association", button_type: "default").tap do |button|
        button.js_on_click(custom_js("toggleTapMode", tap_mode_toggle: button))
      end
      display_title_mode_toggle = bokeh_models.Button.new(label: "Display mode: title", button_type: "default").tap do |button|
        button.js_on_click(custom_js("toggleDisplayTitleMode", display_title_mode_toggle: button))
      end

      plot = bokeh_models.Plot.new(
        sizing_mode: "stretch_both",
        x_range: bokeh_models.Range1d.new(start: x_min - x_padding, end: x_max + x_padding),
        y_range: bokeh_models.Range1d.new(start: y_min - y_padding, end: y_max + y_padding),
        tools: [
          wheel_zoom_tool = bokeh_models.WheelZoomTool.new,
          bokeh_models.ResetTool.new,
          bokeh_models.PanTool.new,
          tap_tool = bokeh_models.TapTool.new,
        ],
      ).tap do |plot|
        plot.toolbar.active_scroll = wheel_zoom_tool
        plot.renderers.append(graph_renderer.rect_renderer)
        plot.renderers.append(graph_renderer.circle_renderer)
        plot.add_layout(default_label)
        plot.add_layout(cardinality_label_set)
        # plot.add_layout(title_label)
        # plot.add_layout(columns_label)
        plot.x_range.js_on_change("start", custom_js("triggerZoom", search_box: search_box))
        plot.x_range.js_on_change("end", custom_js("triggerZoom", search_box: search_box))
        plot.js_on_event("mousemove", custom_js("toggleHovered"))
        plot.js_on_event("mousemove", bokeh_models.CustomJS.new(
          code: save_mouse_position
          ))
        plot.js_on_event("reset", custom_js("resetPlot", search_box: search_box, zoom_mode_toggle: zoom_mode_toggle, tap_mode_toggle: tap_mode_toggle, display_title_mode_toggle: display_title_mode_toggle))
      end

      left_spacer = bokeh_models.Spacer.new(width: 0, sizing_mode: "stretch_width")
      right_spacer = bokeh_models.Spacer.new(width: 30, sizing_mode: "fixed")
      zoom_in_button = bokeh_models.Button.new(label: "Zoom In", button_type: "primary").tap do |button|
        button.js_on_click(custom_js("zoomIn", search_box: search_box, zoom_mode_toggle: zoom_mode_toggle))
      end
      zoom_out_button = bokeh_models.Button.new(label: "Zoom Out", button_type: "success").tap do |button|
        button.js_on_click(custom_js("zoomOut", search_box: search_box, zoom_mode_toggle: zoom_mode_toggle))
      end
      graph_renderer.node_renderer.data_source.selected.js_on_change("indices", custom_js("toggleTapped", search_box: search_box, zoom_mode_toggle: zoom_mode_toggle, tap_mode_toggle: tap_mode_toggle))

      bokeh_models.Column.new(
        children: [
          bokeh_models.Row.new(
            children: [
              left_spacer,
              graph_renderer.selecting_node_label,
              search_box,
              zoom_mode_toggle,
              tap_mode_toggle,
              display_title_mode_toggle,
              zoom_in_button,
              zoom_out_button,
              right_spacer,
            ],
            sizing_mode: "stretch_width",
          ),
          plot,
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

    def save_mouse_position
      <<~JS
        if (window.saveMousePosition !== undefined) { clearTimeout(window.saveMousePosition) }
        window.saveMousePosition = setTimeout(function() {
          window.lastMouseX = cb_obj.x
          window.lastMouseY = cb_obj.y
        }, 100)
      JS
    end

    def custom_js(function_name, search_box: nil, zoom_mode_toggle: nil, tap_mode_toggle: nil, display_title_mode_toggle: nil)
      bokeh_models.CustomJS.new(
        args: graph_renderer.js_args.merge(
          searchBox: search_box,
          zoomModeToggle: zoom_mode_toggle,
          tapModeToggle: tap_mode_toggle,
          displayTitleModeToggle: display_title_mode_toggle,
        ),
        code: [graph_manager, "graphManager.#{function_name}()"].join("\n"),
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

    def search_box
      @search_box ||= bokeh_models.TextInput.new(placeholder: "🔍 Search model", width: 200).tap do |input|
        input.js_on_change("value", custom_js("searchNodes", search_box: input))
      end
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
