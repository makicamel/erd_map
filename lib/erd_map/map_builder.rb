# frozen_string_literal: true

module ErdMap
  class MapBuilder
    CHUNK_SIZE = 3
    VISIBLE = 1.0
    TRANSLUCENT = 0.01

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
      layout = nx.spring_layout(whole_graph, seed: 1, k: 0.1)

      graph_renderer = bokeh_plotting.from_networkx(whole_graph, layout).tap do |renderer|
        node_alpha = PyCall::List.new(layout.keys).map do |node_name|
          nodes_with_chunk_index[node_name].zero? ? VISIBLE : TRANSLUCENT
        end
        renderer.node_renderer.data_source.data["alpha"] = node_alpha

        edge_source = renderer.edge_renderer.data_source
        edge_alpha = edge_source.data["start"].map.with_index do |_, i|
          start_node = edge_source.data["start"][i]
          end_node = edge_source.data["end"][i]
          (nodes_with_chunk_index[start_node].zero? && nodes_with_chunk_index[end_node].zero?) ? VISIBLE : TRANSLUCENT
        end
        renderer.edge_renderer.data_source.data["alpha"] = edge_alpha

        renderer.node_renderer.glyph = bokeh_models.Circle.new(
          radius: 40,
          radius_units: "screen",
          fill_alpha: { field: "alpha" },
          fill_color: "blue",
          line_alpha: { field: "alpha" },
        )
        renderer.edge_renderer.glyph = bokeh_models.MultiLine.new(
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

      coordinates = PyCall::List.new(layout.values).map { |coordinate| [coordinate[0].to_f, coordinate[1].to_f] }
      graph_renderer.node_renderer.data_source.data["x"] = coordinates.map(&:first)
      graph_renderer.node_renderer.data_source.data["y"] = coordinates.map(&:last)

      padding_ratio = 0.1
      x_min, x_max, y_min, y_max = [:first, :last].flat_map { |i| coordinates.map(&i).minmax }
      x_padding, y_padding = [(x_max - x_min) * padding_ratio, (y_max - y_min) * padding_ratio]

      bokeh_models.Plot.new(
        sizing_mode: "stretch_both",
        x_range: bokeh_models.Range1d.new(start: x_min - x_padding, end: x_max + x_padding),
        y_range: bokeh_models.Range1d.new(start: y_min - y_padding, end: y_max + y_padding),
        tools: [
          wheel_zoom_tool = bokeh_models.WheelZoomTool.new,
          bokeh_models.BoxZoomTool.new,
          bokeh_models.ResetTool.new,
          bokeh_models.PanTool.new
        ],
      ).tap do |plot|
        plot.toolbar.active_scroll = wheel_zoom_tool
        plot.renderers.append(graph_renderer)
        plot.add_layout(labels)
        plot.x_range.js_on_change("start", bokeh_models.CustomJS.new(
          args: { graph_renderer: graph_renderer },
          code: change_visibility_with_zoom
        ))
        plot.x_range.js_on_change("end", bokeh_models.CustomJS.new(
          args: { graph_renderer: graph_renderer },
          code: change_visibility_with_zoom
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

    def change_visibility_with_zoom
      <<~JS
        const layoutsByChunk = #{layouts_by_chunk.to_json}
        const chunkedNodes   = #{chunked_nodes.to_json}
        const nodesWithChunkIndex = {}
        chunkedNodes.forEach((chunk, i) => {
          chunk.forEach((n) => { nodesWithChunkIndex[n] = i })
        })

        const nodeSource = graph_renderer.node_renderer.data_source
        const edgeSource = graph_renderer.edge_renderer.data_source
        const nodesAlpha = nodeSource.data["alpha"]
        const nodesIndex = nodeSource.data["index"]
        const nodesX = nodeSource.data["x"]
        const nodesY = nodeSource.data["y"]
        const startEdges = edgeSource.data["start"]
        const targetEdges= edgeSource.data["end"]
        const edgesAlpha = edgeSource.data["alpha"]

        let currentRange = cb_obj.end - cb_obj.start
        if (window.stableRange === undefined) { window.stableRange = currentRange }
        if (window.displayChunksCount === undefined) { window.displayChunksCount = 0 }
        if (window.zoomTimeout !== undefined) { clearTimeout(window.zoomTimeout) }

        window.zoomTimeout = setTimeout(() => {
          const stableRange = window.stableRange
          let displayChunksCount = window.displayChunksCount
          // distance < 0: Zoom in
          // 0 < distance: Zoom out
          let distance = currentRange - stableRange
          const threshold = stableRange * 0.1
          if (Math.abs(distance) >= Math.abs(threshold)) {
            if (distance < 0) { // Zoom in
              displayChunksCount = Math.min(displayChunksCount + 1, chunkedNodes.length - 1)
            } else { // Zoom out
              displayChunksCount = Math.max(displayChunksCount - 1, 0)
            }
          }
          window.displayChunksCount = displayChunksCount
          window.stableRange = currentRange

          const selectedLayout = layoutsByChunk[displayChunksCount]
          for (let i = 0; i < nodesIndex.length; i++) {
            const nodeName = nodesIndex[i]
            const chunkIndex = nodesWithChunkIndex[nodeName]

            if (selectedLayout[nodeName]) {
              const [newX, newY] = selectedLayout[nodeName]
              nodesX[i] = newX
              nodesY[i] = newY
            }

            if (chunkIndex <= displayChunksCount) {
              nodesAlpha[i] = #{VISIBLE}
            } else {
              nodesAlpha[i] = #{TRANSLUCENT}
            }
          }

          for (let i = 0; i < startEdges.length; i++) {
            const source = startEdges[i]
            const target = targetEdges[i]
            const sourceIndex = nodesWithChunkIndex[source]
            const targetIndex = nodesWithChunkIndex[target]

            if (
              sourceIndex <= displayChunksCount &&
              targetIndex <= displayChunksCount &&
              selectedLayout[source] !== undefined &&
              selectedLayout[target] !== undefined
            ) {
              edgesAlpha[i] = #{VISIBLE}
            } else {
              edgesAlpha[i] = #{TRANSLUCENT}
            }
          }

          nodeSource.change.emit()
          edgeSource.change.emit()
        }, 200)
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
          model.reflect_on_all_associations(association_type).each do |target_association|
            target = target_association.name.to_s.singularize.camelize
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

    # @return Array: [{ node_name: [x, y] }, { node_name: [x, y] }, ...]
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

    # [[node_name, node_name, ...], [node_name, node_name, ...], ...]
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

    # { node_name => chunk_index }
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
