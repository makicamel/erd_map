# frozen_string_literal: true

module ErdMap
  class MapBuilder
    def execute
      import_modules
      whole_graph = build_whole_graph
      filtered_graph = build_filtered_graph(whole_graph)
      render(filtered_graph)
    end

    private

    attr_reader :nx, :bokeh_io, :bokeh_models, :bokeh_plotting

    def import_modules
      @nx, @bokeh_io, @bokeh_models, @bokeh_plotting, @bokeh_palettes = ErdMap.py_call_modules.imported_modules
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

    def build_filtered_graph(whole_graph)
      filtered_graph = nx.Graph.new
      top_nodes = nx.eigenvector_centrality(whole_graph) # { NodeLabel => value }
        .sort_by(&:last)
        .last(display_nodes_count)
        .map(&:first)
      top_nodes.each { |node| filtered_graph.add_node(node) }
      PyCall::List.new(whole_graph.edges).each do |source, target|
        if top_nodes.include?(source) && top_nodes.include?(target)
          filtered_graph.add_edge(source, target)
        end
      end
      filtered_graph
    end

    def render(graph)
      layout = nx.spring_layout(graph, seed: 1)
      graph_renderer = bokeh_plotting.from_networkx(graph, layout).tap do |renderer|
        renderer.node_renderer.glyph = bokeh_models.Circle.new(radius: 0.05, fill_alpha: 0.2, fill_color: "white")
        renderer.edge_renderer.glyph = bokeh_models.MultiLine.new(line_alpha: 0.8, line_width: 1)
      end

      plot = bokeh_models.Plot.new
      plot.add_tools(
        bokeh_models.HoverTool.new(tooltips: [["Node", "@index"]]),
        bokeh_models.WheelZoomTool.new,
        bokeh_models.BoxZoomTool.new,
        bokeh_models.ResetTool.new,
      )
      plot.renderers.append(graph_renderer)

      tmp_dir = Rails.root.join("tmp", "erd_map")
      FileUtils.makedirs(tmp_dir) unless Dir.exist?(tmp_dir)
      output_path = File.join(tmp_dir, "result.html")

      bokeh_io.output_file(output_path)
      bokeh_io.save(plot)
      puts output_path
    end

    def display_nodes_count
      @display_nodes_count ||= 10
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
