# frozen_string_literal: true

module ErdMap
  class Graph
    CHUNK_SIZE = 3
    MAX_COMMUNITY_SIZE = 20

    # @return Array: [{ "NodeA" => [x, y] }, { "NodeA" => [x, y], "NodeB" => [x, y], "NodeC" => [x, y] }, ...]
    def layouts_by_chunk
      return @layouts_by_chunk if @layouts_by_chunk

      @layouts_by_chunk = []

      chunked_nodes.each_with_index do |_, i|
        display_nodes = chunked_nodes[0..i].flatten
        nodes_size = display_nodes.size
        k = 1.0 / Math.sqrt(nodes_size) * 3.0

        subgraph = whole_graph.subgraph(display_nodes)
        layout = networkx.spring_layout(subgraph, seed: 1, k: k)

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

      centralities = networkx.eigenvector_centrality(whole_graph) # { node_name => centrality }
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

    # @return Hash: { String: Integer }
    def node_with_community_index
      return @node_with_community_index if @node_with_community_index

      whole_communities = networkx_community.louvain_communities(whole_graph).map { |communities| PyCall::List.new(communities).to_a }
      communities = split_communities(whole_graph, whole_communities)

      @node_with_community_index = {}
      communities.each_with_index do |community, i|
        community.each do |node_name|
          @node_with_community_index[node_name] = i
        end
      end
      @node_with_community_index
    end

    def initial_nodes
      chunked_nodes.first
    end

    def initial_layout
      layouts_by_chunk.first
    end

    def whole_layout
      layouts_by_chunk.last
    end

    def node_names
      @node_names ||= PyCall::List.new(whole_graph.nodes)
    end

    def edges
      @edges ||= PyCall::List.new(whole_graph.edges)
    end

    def node_radius
      @node_radius ||= node_names.map { |node_name| nodes_with_radius_according_to_chunk_index[node_name] }
    end

    def connections
      @connections ||= edges.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(a, b), hash|
        hash[a] << b
        hash[b] << a
      end
    end

    def nodes_with_i18n_labels
      return @nodes_with_i18n_labels if @nodes_with_i18n_labels
      @nodes_with_i18n_labels = {}
      whole_models.each do |model|
        @nodes_with_i18n_labels[model.name] = model.model_name.human(default: "")
      end
      @nodes_with_i18n_labels
    end

    def association_columns
      return @association_columns if @association_columns

      @association_columns = Hash.new { |hash, key| hash[key] = [] }
      whole_models.each do |model|
        model.reflect_on_all_associations(:belongs_to).select { |mod| !mod.options[:polymorphic] }.map do |target|
          if target.try(:foreign_key) && model.column_names.include?(target.foreign_key)
            @association_columns[model.name] << target.foreign_key
          end
        end
      end
      @association_columns
    end

    def node_colors
      return @node_colors if @node_colors

      palette = [
        "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99",
        "#e74446", "#fdbf6f", "#ff7f00", "#cab2d6", "#7850a4",
        "#ffff99", "#b8693d", "#8dd3c7", "#ffffb3", "#bebada",
        "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5",
        "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#1b9e77",
        "#d95f02", "#7570b3", "#ef73b2", "#66a61e", "#e6ab02"
      ]
      community_map = node_with_community_index
      @node_colors = node_names.map do |node_name|
        community_index = community_map[node_name]
        palette[community_index % palette.size]
      end
    end

    private

    attr_reader :networkx, :networkx_community
    attr_reader :whole_graph

    def initialize
      import_modules = ErdMap.py_call_modules.imported_modules
      @networkx = import_modules[:networkx]
      @networkx_community = import_modules[:networkx_community]
      @whole_graph = build_whole_graph
    end

    def whole_models
      Rails.application.eager_load!
      @whole_models ||= ActiveRecord::Base.descendants
        .reject { |model| model.name.in?(%w[ActiveRecord::SchemaMigration ActiveRecord::InternalMetadata]) }
        .select(&:table_exists?)
    end

    def build_whole_graph
      whole_graph = networkx.Graph.new

      whole_models.each do |model|
        whole_graph.add_node(model.name)
        [:has_many, :has_one, :belongs_to].each do |association_type|
          model
            .reflect_on_all_associations(association_type)
            .select { |mod| !mod.options[:polymorphic] && !mod.options[:anonymous_class] }
            .map { |mod| mod.klass.name }
            .uniq
            .map do |target|
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

    # { "NodeA" => 0, "NodeB" => 0, "NodeC" => 1, ... }
    def nodes_with_chunk_index
      return @nodes_with_chunk_index if @nodes_with_chunk_index
      @nodes_with_chunk_index = {}
      chunked_nodes.each_with_index do |chunk, i|
        chunk.each { |node_name| @nodes_with_chunk_index[node_name] = i }
      end
      @nodes_with_chunk_index
    end

    def nodes_with_radius_according_to_chunk_index
      return @nodes_with_radius_according_to_chunk_index if @nodes_with_radius_according_to_chunk_index

      max_node_size = 60
      min_node_size = 20
      node_size_step = 10

      @nodes_with_radius_according_to_chunk_index = {}
      chunked_nodes.each_with_index do |chunk, chunk_index|
        chunk.each do |node_name|
          size = max_node_size - (chunk_index * node_size_step)
          @nodes_with_radius_according_to_chunk_index[node_name] = (size < min_node_size) ? min_node_size : size
        end
      end
      @nodes_with_radius_according_to_chunk_index
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
  end
end
