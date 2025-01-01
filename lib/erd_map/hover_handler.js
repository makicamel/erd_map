(function() {
  const displayChunksCount = window.displayChunksCount || 0
  const selectedLayout = JSON.parse(layoutsByChunk)[displayChunksCount]
  const connections = JSON.parse(connectionsData)
  const nodeSource = graphRenderer.node_renderer.data_source
  const edgeSource = graphRenderer.edge_renderer.data_source
  const nodesIndex = nodeSource.data["index"]
  const startNodes = edgeSource.data['start']
  const targetNodes = edgeSource.data['end']

  const { closestNodeName, minmumDistance } = findClosestNodeWithMinmumDistance(cb_obj, nodesIndex, selectedLayout, window)

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
})()
