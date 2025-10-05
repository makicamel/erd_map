# frozen_string_literal: true

module ErdMap
  class Plot
    extend Forwardable
    def_delegators :@plot, :renderers, :add_layout

    def plot
      return @plot if @plot

      padding_ratio = 0.1
      x_min, x_max, y_min, y_max = graph.initial_layout.values.transpose.map(&:minmax).flatten
      x_padding, y_padding = [(x_max - x_min) * padding_ratio, (y_max - y_min) * padding_ratio]
      @plot = bokeh_models.Plot.new(
        sizing_mode: "stretch_both",
        x_range: bokeh_models.Range1d.new(start: x_min - x_padding, end: x_max + x_padding),
        y_range: bokeh_models.Range1d.new(start: y_min - y_padding, end: y_max + y_padding),
        tools: [
          wheel_zoom_tool = bokeh_models.WheelZoomTool.new,
          bokeh_models.ResetTool.new,
          bokeh_models.PanTool.new,
          bokeh_models.TapTool.new,
        ],
      ).tap do |plot|
        plot.toolbar.active_scroll = wheel_zoom_tool
      end
    end

    def header
      @header.to_a
    end

    private

    attr_reader :graph

    def initialize(graph)
      @graph = graph
      @header = Header.new
      register_callback
    end

    def register_callback
      plot.x_range.js_on_change("start", custom_js("triggerZoom"))
      plot.x_range.js_on_change("end", custom_js("triggerZoom"))
      plot.js_on_event("mousemove", custom_js("toggleHovered"))
      plot.js_on_event("mousemove", bokeh_models.CustomJS.new(code: save_mouse_position))
      plot.js_on_event("reset", custom_js("resetPlot"))
    end

    def bokeh_models
      @bokeh_models ||= ErdMap.py_call_modules.imported_modules[:bokeh_models]
    end

    def custom_js(function_name)
      bokeh_models.CustomJS.new(
        code: <<~JS
          window.graphManager.cbObj = cb_obj
          window.graphManager.#{function_name}()
        JS
      )
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

    class Header
      extend Forwardable
      ACCESSIBLE_PARTS = [:search_box, :selecting_node_label, :zoom_mode_toggle, :tap_mode_toggle, :display_title_mode_toggle]

      def to_a
        [
          :left_spacer,
          :selecting_node_label,
          :search_box,
          :zoom_mode_toggle,
          :tap_mode_toggle,
          :display_title_mode_toggle,
          :re_layout_button,
          :zoom_in_button,
          :zoom_out_button,
          :re_compute_button,
          :right_spacer,
        ].map { |name| @header[name] }
      end

      private

      ACCESSIBLE_PARTS.each do |name|
        define_method(name) { @header[name] }
      end

      def initialize
        @header = {
          left_spacer: left_spacer,
          selecting_node_label: selecting_node_label,
          search_box: search_box,
          zoom_mode_toggle: zoom_mode_toggle,
          tap_mode_toggle: tap_mode_toggle,
          display_title_mode_toggle: display_title_mode_toggle,
          re_layout_button: re_layout_button,
          zoom_in_button: zoom_in_button,
          zoom_out_button: zoom_out_button,
          re_compute_button: re_compute_button,
          right_spacer: right_spacer,
        }
      end

      def left_spacer
        bokeh_models.Spacer.new(width: 0, sizing_mode: "stretch_width")
      end

      def right_spacer
        bokeh_models.Spacer.new(width: 30, sizing_mode: "fixed")
      end

      def selecting_node_label
        bokeh_models.Div.new(
          text: "",
          height: 28,
          styles: { display: :flex, align_items: :center },
        )
      end

      def search_box
        bokeh_models.TextInput.new(placeholder: "🔍 Search model", width: 200).tap do |input|
          input.js_on_change("value", custom_js("searchNodes"))
        end
      end

      def zoom_mode_toggle
        bokeh_models.Button.new(label: "Wheel mode: fix", button_type: "default").tap do |button|
          button.js_on_click(custom_js("toggleZoomMode"))
        end
      end

      def tap_mode_toggle
        bokeh_models.Button.new(label: "Tap mode: association", button_type: "default").tap do |button|
          button.js_on_click(custom_js("toggleTapMode"))
        end
      end

      def display_title_mode_toggle
        bokeh_models.Button.new(label: "Display mode: title", button_type: "default").tap do |button|
          button.js_on_click(custom_js("toggleDisplayTitleMode"))
        end
      end

      def re_layout_button
        bokeh_models.Button.new(label: "Re-Layout", button_type: "default").tap do |button|
          button.js_on_click(custom_js("reLayout"))
        end
      end

      def zoom_in_button
        bokeh_models.Button.new(label: "Zoom In", button_type: "primary").tap do |button|
          button.js_on_click(custom_js("zoomIn",))
        end
      end

      def zoom_out_button
        bokeh_models.Button.new(label: "Zoom Out", button_type: "success").tap do |button|
          button.js_on_click(custom_js("zoomOut"))
        end
      end

      def re_compute_button
        bokeh_models.Button.new(label: "Re-Compute", button_type: "default").tap do |button|
          button.js_on_click(
            bokeh_models.CustomJS.new(
              args: { button: button },
              code: <<~JS
                button.disabled = true
                button.label = "Computing ..."

                const form = document.createElement("form")
                form.method = "POST"
                form.action = "/erd_map"
                form.style.display = "none"
                const input = document.createElement("input")
                input.type = "hidden"
                input.name = "_method"
                input.value = "PUT"
                form.appendChild(input)
                document.body.appendChild(form)
                form.submit()
              JS
            )
          )
        end
      end

      def bokeh_models
        @bokeh_models ||= ErdMap.py_call_modules.imported_modules[:bokeh_models]
      end

      def custom_js(function_name)
        bokeh_models.CustomJS.new(
          code: <<~JS
            window.graphManager.cbObj = cb_obj
            window.graphManager.#{function_name}()
          JS
        )
      end
    end

    Header::ACCESSIBLE_PARTS.each do |name|
      public define_method(name) { @header.__send__(name) }
    end
  end
end
