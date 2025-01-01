(function() {
  const layoutsByChunk = JSON.parse(layoutsByChunkData)
  const chunkedNodes = JSON.parse(chunkedNodesData)
  const nodesWithChunkIndex = {}
  chunkedNodes.forEach((chunk, i) => {
    chunk.forEach((n) => { nodesWithChunkIndex[n] = i })
  })
  const nodeSource = graphRenderer.node_renderer.data_source
  const edgeSource = graphRenderer.edge_renderer.data_source
  const nodesAlpha = nodeSource.data["alpha"]
  const nodesIndex = nodeSource.data["index"]
  const startEdges = edgeSource.data["start"]
  const targetEdges = edgeSource.data["end"]
  const edgesAlpha = edgeSource.data["alpha"]

  let currentRange = cb_obj.end - cb_obj.start
  if (window.stableRange === undefined) { window.stableRange = currentRange }
  if (window.displayChunksCount === undefined) { window.displayChunksCount = 0 }
  if (window.zoomTimeout !== undefined) { clearTimeout(window.zoomTimeout) }

  const previousDisplayChunksCount = window.displayChunksCount

  window.zoomTimeout = setTimeout(handleZoom, 200)

  function handleZoom() {
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

    if (displayChunksCount === previousDisplayChunksCount) { return }

    const selectedLayout = layoutsByChunk[displayChunksCount]
    const [nodesX, nodesY] = updateNodeXY(nodeSource, nodesIndex, selectedLayout)
    nodesIndex.forEach((nodeName, i) => {
      const chunkIndex = nodesWithChunkIndex[nodeName]
      nodesAlpha[i] = chunkIndex <= displayChunksCount ? VISIBLE : TRANSLUCENT
    })

    startEdges.forEach((source, i) => {
      const target = targetEdges[i]
      const sourceIndex = nodesWithChunkIndex[source]
      const targetIndex = nodesWithChunkIndex[target]
      const displayEdge = sourceIndex <= displayChunksCount && targetIndex <= displayChunksCount && selectedLayout[source] !== undefined && selectedLayout[target] !== undefined
      edgesAlpha[i] = displayEdge ? VISIBLE : TRANSLUCENT
    })

    const mousePosition = new Object({ x: window.lastMouseX || 0, y: window.lastMouseY || 0 })
    const { closestNodeName } = findClosestNodeWithMinmumDistance(
      mousePosition,
      nodesIndex,
      layoutsByChunk[previousDisplayChunksCount],
      window,
    )

    if (closestNodeName && selectedLayout[closestNodeName]) {
      const closestNode = selectedLayout[closestNodeName]
      window.previousShiftX = mousePosition.x - closestNode[0]
      window.previousShiftY = mousePosition.y - closestNode[1]
      nodesIndex.forEach((_nodeName, i) => {
        nodesX[i] += window.previousShiftX
        nodesY[i] += window.previousShiftY
      })
    }

    nodeSource.change.emit()
    edgeSource.change.emit()

    const newGraphLayout = {}
    nodesIndex.forEach((nodeName, i) => {
      newGraphLayout[nodeName] = [nodesX[i], nodesY[i]]
    })
    layoutProvider.graph_layout = newGraphLayout
    layoutProvider.change.emit()
  }
})()
