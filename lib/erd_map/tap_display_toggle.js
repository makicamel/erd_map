(function() {
  const nodeSource = graphRenderer.node_renderer.data_source
  const edgeSource = graphRenderer.edge_renderer.data_source
  const nodesIndex = nodeSource.data["index"]

  const connections = JSON.parse(connectionsData)
  const layoutsByChunk = JSON.parse(layoutsByChunkData)
  const wholeLayout = layoutsByChunk.slice(-1)[0]
  const tappedNode = findTappedNode()

  if (window.selectingNode == tappedNode) {
    window.selectingNode = null
  } else {
    window.selectingNode = tappedNode
    const connectedNodes = connections[tappedNode] || []
    connectedNodes.push(tappedNode)

    nodeSource.data["alpha"] = nodesIndex.map(nodeName =>
      connectedNodes.includes(nodeName) ? VISIBLE : TRANSLUCENT
    )
    const sourceNodes = edgeSource.data["start"]
    const targetNodes = edgeSource.data["end"]
    edgeSource.data["alpha"] = sourceNodes.map((sourceNode, i) =>
      connectedNodes.includes(sourceNode) && connectedNodes.includes(targetNodes[i]) ? VISIBLE : TRANSLUCENT
    )

    const [nodesX, nodesY] = updateNodeXY(nodeSource, nodesIndex, wholeLayout)
    nodesIndex.forEach((nodeName, i) => {
      nodesX[i] += window.previousShiftX || 0
      nodesY[i] += window.previousShiftY || 0
      wholeLayout[nodeName][0] += window.previousShiftX || 0
      wholeLayout[nodeName][1] += window.previousShiftY || 0
    })

    nodeSource.change.emit()
    edgeSource.change.emit()

    layoutProvider.graph_layout = wholeLayout
    layoutProvider.change.emit()
  }

  function findTappedNode() {
    const displayChunksCount = window.displayChunksCount || 0
    const selectedLayout = layoutsByChunk[displayChunksCount]
    const currentDisplayNodes = window.selectingNode ? connections[window.selectingNode] : Object.keys(selectedLayout)
    const selectedNodesIndices = cb_data.source.selected.indices
    const tappedNodeIndex = selectedNodesIndices.find(id => currentDisplayNodes.includes(nodesIndex[id]))
    return nodesIndex[tappedNodeIndex]
  }
})()
