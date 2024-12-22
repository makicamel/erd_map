# frozen_string_literal: true

module ErdMap
  class MapBuilder
    CHUNK_SIZE = 8
    VISIBLE = 1.0
    TRANSLUCENT = 0.2

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
      layout = nx.spring_layout(whole_graph, seed: 1)

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

        max_label_length = PyCall::List.new(layout.keys).map(&:size).max
        char_width = 10
        renderer.node_renderer.glyph = bokeh_models.Rect.new(
          width: max_label_length * char_width,
          height: 60,
          width_units: "screen",
          height_units: "screen",
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
      ).tap do |plot|
        plot.add_tools(
          bokeh_models.HoverTool.new(tooltips: [["Node", "@index"]]),
          bokeh_models.WheelZoomTool.new,
          bokeh_models.BoxZoomTool.new,
          bokeh_models.ResetTool.new,
          bokeh_models.PanTool.new,
        )
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
        const chunkedNodes = #{chunked_nodes.to_json}
        const nodesWithChunkIndex = {}
        chunkedNodes.forEach((chunk, i) => {
          chunk.forEach((n) => { nodesWithChunkIndex[n] = i })
        })
        const range = cb_obj.end - cb_obj.start
        const thresholds = [10, 5, 2, 1]

        let showChunksCount = 1
        for (let i = 0; i < thresholds.length; i++) {
          if (range < thresholds[i]) {
            showChunksCount = i + 1
          }
        }

        const nodeSource = graph_renderer.node_renderer.data_source
        const edgeSource = graph_renderer.edge_renderer.data_source

        const nodeAlpha = nodeSource.data["alpha"]
        const nodeIndex = nodeSource.data["index"]

        for(let i = 0; i < nodeIndex.length; i++) {
          const nodeName = nodeIndex[i]
          const chunkIndex = nodesWithChunkIndex[nodeName]
          if (chunkIndex < showChunksCount) {
            nodeAlpha[i] = #{VISIBLE}
          } else {
            nodeAlpha[i] = #{TRANSLUCENT}
          }
        }

        const startEdge = edgeSource.data["start"]
        const endEdge   = edgeSource.data["end"]
        const alphaEdge = edgeSource.data["alpha"]

        for(let i = 0; i < startEdge.length; i++) {
          const source = startEdge[i];
          const target = endEdge[i];
          const sourceIndex = nodesWithChunkIndex[source];
          const targetIndex = nodesWithChunkIndex[target];
          if (sourceIndex < showChunksCount && targetIndex < showChunksCount) {
            alphaEdge[i] = #{VISIBLE}
          } else {
            alphaEdge[i] = #{TRANSLUCENT}
          }
        }

        nodeSource.change.emit()
        edgeSource.change.emit()
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

    # [[node_name, node_name, ...], [node_name, node_name, ...], ...]
    def chunked_nodes
      return @chunked_nodes if @chunked_nodes
      sorted_nodes = nx.eigenvector_centrality(whole_graph) # { node_name => centrality }
        .sort_by(&:last)
        .reverse
        .map(&:first)
      @chunked_nodes = sorted_nodes.each_slice(CHUNK_SIZE).to_a
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
