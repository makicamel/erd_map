# frozen_string_literal: true

module ErdMap
  class MapBuilder
    CHUNK_SIZE = 3
    VISIBLE = 1.0
    TRANSLUCENT = 0.01
    BASIC_COLOR = "skyblue"
    HIGHLIGHT_COLOR = "orange"
    BASIC_SIZE = 40
    EMPTHASIS_SIZE = 60

    def execute
      import_modules
      save(build_plot)
    end

    private

    attr_reader :nx, :bokeh_io, :bokeh_models, :bokeh_plotting

    def import_modules
      @nx, @bokeh_io, @bokeh_models, @bokeh_plotting, @bokeh_palettes = ErdMap.py_call_modules.imported_modules
    end

    def build_plot
      initial_nodes = chunked_nodes.first
      initial_layout = layouts_by_chunk.first

      node_names = PyCall::List.new(whole_graph.nodes)
      nodes_x, nodes_y = node_names.map { |node| initial_layout[node] ? initial_layout[node] : [0.0, 0.0] }.transpose

      graph_layout = node_names.zip(nodes_x, nodes_y).map { |node, x, y| [node, [x, y]] }.to_h
      layout_provider = bokeh_models.StaticLayoutProvider.new(graph_layout: graph_layout)

      graph_renderer = bokeh_models.GraphRenderer.new(layout_provider: layout_provider).tap do |renderer|
        nodes_alpha = node_names.map { |node| initial_nodes.include?(node) ? VISIBLE : TRANSLUCENT }
        renderer.node_renderer.data_source = bokeh_models.ColumnDataSource.new(
          data: {
            index: node_names,
            alpha: nodes_alpha,
            x: nodes_x,
            y: nodes_y,
            radius: node_names.map { BASIC_SIZE },
            fill_color: node_names.map { BASIC_COLOR },
          }
        )
        renderer.node_renderer.glyph = bokeh_models.Circle.new(
          radius: "radius",
          radius_units: "screen",
          fill_color: { field: "fill_color" },
          fill_alpha: { field: "alpha" },
          line_alpha: { field: "alpha" },
        )

        edges = PyCall::List.new(whole_graph.edges)
        edge_start, edge_end = edges.map { |edge| [edge[0], edge[1]] }.transpose
        edges_alpha = edges.map { |edge| initial_nodes.include?(edge[0]) && initial_nodes.include?(edge[1]) ? VISIBLE : TRANSLUCENT }
        renderer.edge_renderer.data_source = bokeh_models.ColumnDataSource.new(
          data: {
            start: edge_start,
            end: edge_end,
            alpha: edges_alpha,
            line_color: edges.map { "gray" },
          }
        )
        renderer.edge_renderer.glyph = bokeh_models.MultiLine.new(
          line_color: { field: "line_color" },
          line_alpha: { field: "alpha" },
          line_width: 1,
        )
      end

      labels = bokeh_models.LabelSet.new(
        x: "x",
        y: "y",
        text: "index",
        source: graph_renderer.node_renderer.data_source,
        text_font_size: "12pt",
        text_color: "black",
        text_align: "center",
        text_baseline: "middle",
        text_alpha: { field: "alpha" },
      )

      padding_ratio = 0.1
      x_min, x_max, y_min, y_max = initial_layout.values.transpose.map(&:minmax).flatten
      x_padding, y_padding = [(x_max - x_min) * padding_ratio, (y_max - y_min) * padding_ratio]

      bokeh_models.Plot.new(
        sizing_mode: "stretch_both",
        x_range: bokeh_models.Range1d.new(start: x_min - x_padding, end: x_max + x_padding),
        y_range: bokeh_models.Range1d.new(start: y_min - y_padding, end: y_max + y_padding),
        tools: [
          wheel_zoom_tool = bokeh_models.WheelZoomTool.new,
          bokeh_models.BoxZoomTool.new,
          bokeh_models.ResetTool.new,
          bokeh_models.PanTool.new,
        ],
      ).tap do |plot|
        plot.toolbar.active_scroll = wheel_zoom_tool
        plot.renderers.append(graph_renderer)
        plot.add_layout(labels)
        plot.js_on_event("mousemove", bokeh_models.CustomJS.new(
          code: save_mouse_position
        ))
        plot.x_range.js_on_change("start", bokeh_models.CustomJS.new(
          args: {
            graphRenderer: graph_renderer,
            layoutProvider: layout_provider,
            layoutsByChunkData: layouts_by_chunk.to_json,
            chunkedNodesData: chunked_nodes.to_json,
            VISIBLE: VISIBLE,
            TRANSLUCENT: TRANSLUCENT,
          },
          code: zoom_handler
        ))
        plot.x_range.js_on_change("end", bokeh_models.CustomJS.new(
          args: {
            graphRenderer: graph_renderer,
            layoutProvider: layout_provider,
            layoutsByChunkData: layouts_by_chunk.to_json,
            chunkedNodesData: chunked_nodes.to_json,
            VISIBLE: VISIBLE,
            TRANSLUCENT: TRANSLUCENT,
          },
          code: zoom_handler
        ))
        plot.js_on_event("reset", bokeh_models.CustomJS.new(
          args: { layoutProvider: layout_provider, selectedLayout: layouts_by_chunk.first },
          code: reset_plot
        ))

        connections = PyCall::List.new(whole_graph.edges).each_with_object(Hash.new { |h, k| h[k] = [] }) do |(a, b), hash|
          hash[a] << b
          hash[b] << a
        end
        plot.js_on_event("mousemove", bokeh_models.CustomJS.new(
          args: {
            graphRenderer: graph_renderer,
            connectionsData: connections.to_json,
            layoutsByChunk: layouts_by_chunk.to_json,
            BASIC_COLOR: BASIC_COLOR,
            HIGHLIGHT_COLOR: HIGHLIGHT_COLOR,
            BASIC_SIZE: BASIC_SIZE,
            EMPTHASIS_SIZE: EMPTHASIS_SIZE,
          },
          code: hover_handler
        ))
      end
    end

    def save(plot)
      tmp_dir = Rails.root.join("tmp", "erd_map")
      FileUtils.makedirs(tmp_dir) unless Dir.exist?(tmp_dir)
      output_path = File.join(tmp_dir, "result.html")

      bokeh_io.output_file(output_path)
      bokeh_io.save(plot)
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

    def zoom_handler
      js_path = __dir__ + "/zoom_handler.js"
      File.read(js_path)
    end

    def hover_handler
      js_path = __dir__ + "/hover_handler.js"
      File.read(js_path)
    end

    def reset_plot
      <<~JS
        window.previousShiftX = 0
        window.previousShiftY = 0
        window.stableRange = undefined
        window.displayChunksCount = 0
        layoutProvider.graph_layout = #{layouts_by_chunk.first.to_json}
        layoutProvider.change.emit()
      JS
    end

    def whole_graph
      @whole_graph ||= build_whole_graph
    end

    def build_whole_graph
      Rails.application.eager_load!
      whole_graph = nx.Graph.new
      models = ActiveRecord::Base.descendants
        .reject { |model| model.name.in?(%w[ActiveRecord::SchemaMigration ActiveRecord::InternalMetadata]) }
        .select(&:table_exists?)
      models.each do |model|
        whole_graph.add_node(model.name)
        [:has_many, :has_one, :belongs_to].each do |association_type|
          model.reflect_on_all_associations(association_type).map(&:class_name).uniq.map do |target|
            if association_type == :belongs_to
              whole_graph.add_edge(target, model.name)
            else
              whole_graph.add_edge(model.name, target)
            end
          end
        end
      end
      whole_graph
    end

    # @return Array: [{ "NodeA" => [x, y] }, { "NodeA" => [x, y], "NodeB" => [x, y], "NodeC" => [x, y] }, ...]
    def layouts_by_chunk
      return @layouts_by_chunk if @layouts_by_chunk

      @layouts_by_chunk = []

      chunked_nodes.each_with_index do |_, i|
        display_nodes = chunked_nodes[0..i].flatten
        nodes_size = display_nodes.size
        k = 1.0 / Math.sqrt(nodes_size) * 3.0

        subgraph = whole_graph.subgraph(display_nodes)
        layout = nx.spring_layout(subgraph, seed: 1, k: k)

        layout_hash = {}
        layout.each do |node, xy|
          layout_hash[node] = [xy[0].to_f, xy[1].to_f]
        end

        @layouts_by_chunk << layout_hash
      end

      @layouts_by_chunk
    end

    # [[nodeA, nodeB, nodeC], [nodeD, nodeE, nodeF, nodeG, ...], ...]
    def chunked_nodes
      return @chunked_nodes if @chunked_nodes

      centralities = nx.eigenvector_centrality(whole_graph) # { node_name => centrality }
      sorted_nodes = centralities.sort_by { |_node, centrality| centrality }.reverse.map(&:first)

      chunk_sizes = []
      total_nodes = sorted_nodes.size
      while chunk_sizes.sum < total_nodes
        chunk_sizes << (CHUNK_SIZE ** (chunk_sizes.size + 1))
      end

      offset = 0
      @chunked_nodes = chunk_sizes.each_with_object([]) do |size, nodes|
        slice = sorted_nodes[offset, size]
        break nodes if slice.nil? || slice.empty?
        offset += size
        nodes << slice
      end
    end

    # { "NodeA" => 0, "NodeB" => 0, "NodeC" => 1, ... }
    def nodes_with_chunk_index
      return @nodes_with_chunk_index if @nodes_with_chunk_index
      @nodes_with_chunk_index = {}
      chunked_nodes.each_with_index do |chunk, i|
        chunk.each { |node_name| @nodes_with_chunk_index[node_name] = i }
      end
      @nodes_with_chunk_index
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
