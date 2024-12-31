(function() {
  const nodeSource = graphRenderer.node_renderer.data_source
  const edgeSource = graphRenderer.edge_renderer.data_source
  const nodesIndex = nodeSource.data["index"]
  const startNodes = edgeSource.data['start']
  const targetNodes = edgeSource.data['end']

  const connections = JSON.parse(connectionsData)
  const { selectedLayout, showingNodes } = getShowingNodesAndSelectedLayout()
  const { closestNodeName, minmumDistance } = findClosestNodeWithMinmumDistance(cb_obj, nodesIndex, selectedLayout, window, showingNodes)

  if (closestNodeName && minmumDistance < 0.005) {
    const connectedNodes = connections[closestNodeName] || []
    nodeSource.data['radius'] = nodesIndex.map(nodeName => {
      return (nodeName === closestNodeName) ? EMPTHASIS_SIZE : BASIC_SIZE
    })
    nodeSource.data['fill_color'] = nodesIndex.map(nodeName => {
      const isConnectedNode = nodeName === closestNodeName || selectedLayout[nodeName] && connectedNodes.includes(nodeName)
      return isConnectedNode ? HIGHLIGHT_COLOR : BASIC_COLOR
    })
    edgeSource.data['line_color'] = startNodes.map((start, i) => {
      return [start, targetNodes[i]].includes(closestNodeName) ? HIGHLIGHT_COLOR : "gray"
    })
  } else {
    nodeSource.data['radius'] = nodesIndex.map(() => BASIC_SIZE)
    nodeSource.data['fill_color'] = nodesIndex.map(() => BASIC_COLOR)
    edgeSource.data['line_color'] = edgeSource.data['start'].map(() => "gray")
  }

  nodeSource.change.emit()
  edgeSource.change.emit()

  function getShowingNodesAndSelectedLayout() {
    const layoutsByChunk = JSON.parse(layoutsByChunkData)
    let selectedLayout
    let showingNodes
    if (window.selectingNode) {
      selectedLayout = layoutsByChunk.slice(-1)[0]
      showingNodes = connections[window.selectingNode]
      showingNodes.push(window.selectingNode)
    } else {
      const displayChunksCount = window.displayChunksCount || 0
      selectedLayout = layoutsByChunk[displayChunksCount]
      showingNodes = Object.keys(selectedLayout)
    }
    return { selectedLayout: selectedLayout, showingNodes: showingNodes }
  }
})()
