# frozen_string_literal: true

module ErdMap
  class MapBuilder
    CHUNK_SIZE = 3
    VISIBLE = 1.0
    TRANSLUCENT = 0.01
    HIGHLIGHT_NODE_COLOR = "black"
    HIGHLIGHT_EDGE_COLOR = "orange"
    HIGHLIGHT_TEXT_COLOR = "white"
    BASIC_TEXT_COLOR = "black"
    BASIC_SIZE = 40
    EMPTHASIS_SIZE = 60
    MAX_COMMUNITY_SIZE = 20

    def execute
      import_modules
      save(build_plot)
    end

    private

    attr_reader :nx, :bokeh_io, :bokeh_models, :bokeh_plotting, :bokeh_palettes, :networkx_community

    def import_modules
      import_modules = ErdMap.py_call_modules.imported_modules
      @nx = import_modules[:nx]
      @bokeh_io = import_modules[:bokeh_io]
      @bokeh_models = import_modules[:bokeh_models]
      @bokeh_plotting = import_modules[:bokeh_plotting]
      @bokeh_palettes = import_modules[:bokeh_palettes]
      @networkx_community = import_modules[:networkx_community]
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
            fill_color: node_colors,
            original_color: node_colors,
            text_color: node_names.map { BASIC_TEXT_COLOR },
            text_outline_color: node_names.map { nil },
          }
        )
        renderer.node_renderer.glyph = bokeh_models.Circle.new(
          radius: "radius",
          radius_units: "screen",
          fill_color: { field: "fill_color" },
          fill_alpha: { field: "alpha" },
          line_alpha: { field: "alpha" },
        )
        renderer.node_renderer.selection_glyph = renderer.node_renderer.glyph
        renderer.node_renderer.nonselection_glyph = renderer.node_renderer.glyph

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
        text_color: { field: "text_color" },
        text_outline_color: { field: "text_outline_color" },
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
          tap_tool = bokeh_models.TapTool.new,
        ],
      ).tap do |plot|
        plot.toolbar.active_scroll = wheel_zoom_tool
        plot.renderers.append(graph_renderer)
        plot.add_layout(labels)
        plot.js_on_event("mousemove", bokeh_models.CustomJS.new(
          code: save_mouse_position
        ))
        plot.x_range.js_on_change("start", custom_js("triggerZoom", graph_renderer, layout_provider))
        plot.x_range.js_on_change("end", custom_js("triggerZoom", graph_renderer, layout_provider))
        plot.js_on_event("reset", custom_js("resetPlot", graph_renderer, layout_provider))
        plot.js_on_event("mousemove", custom_js("toggleHovered", graph_renderer, layout_provider))
        graph_renderer.node_renderer.data_source.selected.js_on_change("indices", custom_js("toggleTapped", graph_renderer, layout_provider))
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

    def custom_js(function_name, graph_renderer, layout_provider)
      bokeh_models.CustomJS.new(
        args: js_args(graph_renderer, layout_provider),
        code: [graph_manager, "graphManager.#{function_name}()"].join("\n"),
      )
    end

    def js_args(graph_renderer, layout_provider)
      return @js_args if @js_args

      connections = PyCall::List.new(whole_graph.edges).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(a, b), hash|
        hash[a] << b
        hash[b] << a
      end
      @js_args = {
        graphRenderer: graph_renderer,
        layoutProvider: layout_provider,
        connectionsData: connections.to_json,
        layoutsByChunkData: layouts_by_chunk.to_json,
        chunkedNodesData: chunked_nodes.to_json,
        VISIBLE: VISIBLE,
        TRANSLUCENT: TRANSLUCENT,
        HIGHLIGHT_NODE_COLOR: HIGHLIGHT_NODE_COLOR,
        HIGHLIGHT_EDGE_COLOR: HIGHLIGHT_EDGE_COLOR,
        HIGHLIGHT_TEXT_COLOR: HIGHLIGHT_TEXT_COLOR,
        BASIC_TEXT_COLOR: BASIC_TEXT_COLOR,
        BASIC_SIZE: BASIC_SIZE,
        EMPTHASIS_SIZE: EMPTHASIS_SIZE,
      }
    end

    def graph_manager
      return @graph_manager if @graph_manager
      js_path = __dir__ + "/graph_manager.js"
      @graph_manager = File.read(js_path)
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

    def node_colors
      return @node_colors if @node_colors

      palette_size = 23 # Max size of TolRainbow
      palette = bokeh_palettes.TolRainbow[palette_size]
      node_names = PyCall::List.new(whole_graph.nodes)
      community_map = node_with_community_index
      @node_colors = node_names.map do |node_name|
        community_index = community_map[node_name]
        palette[community_index % palette_size]
      end
    end

    # @return Hash: { String: Integer }
    def node_with_community_index
      whole_communities = networkx_community.louvain_communities(whole_graph).map { |communities| PyCall::List.new(communities).to_a }
      communities = split_communities(whole_graph, whole_communities)

      node_with_community_index = {}
      communities.each_with_index do |community, i|
        community.each do |node_name|
          node_with_community_index[node_name] = i
        end
      end
      node_with_community_index
    end

    def split_communities(graph, communities)
      result = []

      communities.each do |community|
        if community.size <= MAX_COMMUNITY_SIZE
          result << community
        else
          subgraph = graph.subgraph(community)
          sub_communities = networkx_community.louvain_communities(subgraph).map { |comm| PyCall::List.new(comm).to_a }
          if sub_communities.size == 1 && (sub_communities[0] - community).empty?
            result << community
          else
            splitted_sub = split_communities(subgraph, sub_communities)
            result.concat(splitted_sub)
          end
        end
      end

      result
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
