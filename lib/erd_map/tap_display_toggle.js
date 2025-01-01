(function() {
  const nodeSource = graphRenderer.node_renderer.data_source
  const edgeSource = graphRenderer.edge_renderer.data_source
  const nodesIndex = nodeSource.data["index"]

  const connections = JSON.parse(connectionsData)
  const layoutsByChunk = JSON.parse(layoutsByChunkData)
  const wholeLayout = layoutsByChunk.slice(-1)[0]
  const tappedNode = findTappedNode()

  if (window.selectingNode && (tappedNode === window.selectingNode || tappedNode === undefined)) {
    window.selectingNode = null
    const chunkedNodes = JSON.parse(chunkedNodesData)
    const nodesWithChunkIndex = {}
    chunkedNodes.forEach((chunk, i) => {
      chunk.forEach((n) => { nodesWithChunkIndex[n] = i })
    })

    const displayChunksCount = window.displayChunksCount || 0
    const selectedLayout = layoutsByChunk[displayChunksCount]
    const [nodesX, nodesY] = updateNodeXY(nodeSource, nodesIndex, selectedLayout)
    nodesIndex.forEach((nodeName, i) => {
      const chunkIndex = nodesWithChunkIndex[nodeName]
      nodeSource.data["alpha"][i] = chunkIndex <= displayChunksCount ? VISIBLE : TRANSLUCENT
    })

    const startEdges = edgeSource.data["start"]
    const targetEdges = edgeSource.data["end"]
    startEdges.forEach((source, i) => {
      const target = targetEdges[i]
      const sourceIndex = nodesWithChunkIndex[source]
      const targetIndex = nodesWithChunkIndex[target]
      const displayEdge = sourceIndex <= displayChunksCount && targetIndex <= displayChunksCount && selectedLayout[source] !== undefined && selectedLayout[target] !== undefined
      edgeSource.data["alpha"][i] = displayEdge ? VISIBLE : TRANSLUCENT
    })
    nodeSource.change.emit()
    edgeSource.change.emit()

    const newGraphLayout = {}
    nodesIndex.forEach((nodeName, i) => {
      newGraphLayout[nodeName] = [nodesX[i], nodesY[i]]
    })
    layoutProvider.graph_layout = newGraphLayout
    layoutProvider.change.emit()
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

  // return [String, undefined]
  function findTappedNode() {
    const displayChunksCount = window.displayChunksCount || 0
    const selectedLayout = layoutsByChunk[displayChunksCount]
    const currentDisplayNodes = window.selectingNode ? connections[window.selectingNode] : Object.keys(selectedLayout)
    const selectedNodesIndices = cb_obj.indices
    const tappedNodeIndex = selectedNodesIndices.find(id => currentDisplayNodes.includes(nodesIndex[id]))
    return nodesIndex[tappedNodeIndex]
  }
})()
