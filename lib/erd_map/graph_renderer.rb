# frozen_string_literal: true

module ErdMap
  class GraphRenderer
    extend Forwardable
    def_delegators :@graph_renderer, :node_renderer

    attr_reader :graph_renderer

    VISIBLE = 1.0
    TRANSLUCENT = 0.01
    HIGHLIGHT_NODE_COLOR = "black"
    HIGHLIGHT_EDGE_COLOR = "orange"
    HIGHLIGHT_TEXT_COLOR = "white"
    BASIC_COLOR = "darkslategray"
    EMPTHASIS_NODE_SIZE = 80

    def selecting_node_label
      @selecting_node_label ||= bokeh_models.Div.new(
        text: "",
        height: 28,
        styles: { display: :flex, align_items: :center },
      )
    end

    def js_args
      @js_args ||= {
        graphRenderer: graph_renderer,
        layoutProvider: layout_provider,
        connectionsData: graph.connections.to_json,
        layoutsByChunkData: graph.layouts_by_chunk.to_json,
        chunkedNodesData: graph.chunked_nodes.to_json,
        nodeWithCommunityIndexData: graph.node_with_community_index.to_json,
        selectingNodeLabel: selecting_node_label,
        VISIBLE: VISIBLE,
        TRANSLUCENT: TRANSLUCENT,
        HIGHLIGHT_NODE_COLOR: HIGHLIGHT_NODE_COLOR,
        HIGHLIGHT_EDGE_COLOR: HIGHLIGHT_EDGE_COLOR,
        HIGHLIGHT_TEXT_COLOR: HIGHLIGHT_TEXT_COLOR,
        BASIC_COLOR: BASIC_COLOR,
        EMPTHASIS_NODE_SIZE: EMPTHASIS_NODE_SIZE,
      }
    end

    private

    attr_reader :bokeh_models
    attr_reader :graph

    def initialize(graph)
      import_modules = ErdMap.py_call_modules.imported_modules
      @bokeh_models = import_modules[:bokeh_models]
      @graph = graph
      @graph_renderer = build_renderer
    end

    def build_renderer
      bokeh_models.GraphRenderer.new(layout_provider: layout_provider).tap do |renderer|
        renderer.node_renderer.data_source = default_node_data_source
        renderer.node_renderer.glyph = circle_glyph
        renderer.node_renderer.selection_glyph = renderer.node_renderer.glyph
        renderer.node_renderer.nonselection_glyph = renderer.node_renderer.glyph

        renderer.edge_renderer.data_source = edge_data_source
        renderer.edge_renderer.glyph = bokeh_models.MultiLine.new(
          line_color: { field: "line_color" },
          line_alpha: { field: "alpha" },
          line_width: 1,
        )
      end
    end

    def default_node_data_source
      nodes_x, nodes_y = graph.node_names.map { |node| graph.initial_layout[node] ? graph.initial_layout[node] : graph.whole_layout[node] }.transpose
      nodes_alpha = graph.node_names.map { |node| graph.initial_layout[node] ? VISIBLE : TRANSLUCENT }

      bokeh_models.ColumnDataSource.new(
        data: {
          index: graph.node_names,
          alpha: nodes_alpha,
          x: nodes_x,
          y: nodes_y,
          radius: graph.node_radius,
          original_radius: graph.node_radius,
          fill_color: graph.node_colors,
          original_color: graph.node_colors,
          text_color: graph.node_names.map { BASIC_COLOR },
          text_outline_color: graph.node_names.map { nil },
        }
      )
    end

    def rect_node_data_source
      nodes_x, nodes_y = graph.node_names.map { |node| graph.initial_layout[node] ? graph.initial_layout[node] : graph.whole_layout[node] }.transpose
      nodes_alpha = graph.node_names.map { |node| graph.initial_layout[node] ? VISIBLE : TRANSLUCENT }

      columns_label = []
      title_label = []
      rect_heights = []
      graph.node_names.map do |node_name|
        columns_text = "\n" + format_text(graph.association_columns[node_name])
        columns_label << columns_text
        title_label << node_name + columns_text.scan("\n").join + "\n"

        padding = 36
        line_count = columns_text.scan("\n").size + 1
        rect_heights << line_count * 20 + padding
      end

      bokeh_models.ColumnDataSource.new(
        data: {
          index: graph.node_names,
          alpha: nodes_alpha,
          x: nodes_x,
          y: nodes_y,
          rect_height: rect_heights,
          title_label: title_label,
          columns_label: columns_label,
          fill_color: graph.node_names.map { "white" },
          original_color: graph.node_names.map { "white" },
          text_color: graph.node_names.map { BASIC_COLOR },
          text_outline_color: graph.node_names.map { nil },
        }
      )
    end

    def format_text(columns)
      max_chars_size = 20
      columns.flat_map { |column| column.scan(/(\w{1,#{max_chars_size}})/) }.join("\n")
    end

    def circle_glyph
      bokeh_models.Circle.new(
        radius: "radius",
        radius_units: "screen",
        fill_color: { field: "fill_color" },
        fill_alpha: { field: "alpha" },
        line_alpha: { field: "alpha" },
      )
    end

    def rect_glyph
      bokeh_models.Rect.new(
        width: 150,
        height: { field: "rect_height" },
        width_units: "screen",
        height_units: "screen",
        fill_color: { field: "fill_color" },
        fill_alpha: { field: "alpha" },
        line_color: BASIC_COLOR,
        line_alpha: { field: "alpha" },
      )
    end

    def edge_data_source
      edge_start, edge_end = graph.edges.map { |edge| [edge[0], edge[1]] }.transpose
      edges_alpha = graph.edges.map { |edge| graph.initial_nodes.include?(edge[0]) && graph.initial_nodes.include?(edge[1]) ? VISIBLE : TRANSLUCENT }
      bokeh_models.ColumnDataSource.new(
        data: {
          start: edge_start,
          end: edge_end,
          alpha: edges_alpha,
          line_color: graph.edges.map { BASIC_COLOR },
        }
      )
    end

    def layout_provider
      return @layout_provider if @layout_provider

      nodes_x, nodes_y = graph.node_names.map { |node| graph.initial_layout[node] ? graph.initial_layout[node] : graph.whole_layout[node] }.transpose
      graph_layout = graph.node_names.zip(nodes_x, nodes_y).map { |node, x, y| [node, [x, y]] }.to_h
      @layout_provider = bokeh_models.StaticLayoutProvider.new(graph_layout: graph_layout)
    end
  end
end
