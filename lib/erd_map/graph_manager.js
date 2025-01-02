class GraphManager {
  constructor({
    graphRenderer,
    layoutProvider,
    connectionsData,
    layoutsByChunkData,
    chunkedNodesData,
    windowObj,
    cbObj,
  }) {
    this.nodeSource = graphRenderer.node_renderer.data_source
    this.edgeSource = graphRenderer.edge_renderer.data_source
    this.layoutProvider = layoutProvider
    this.connections = JSON.parse(connectionsData)
    this.layoutsByChunk = JSON.parse(layoutsByChunkData)
    this.chunkedNodes = JSON.parse(chunkedNodesData)
    this.windowObj = windowObj
    this.cbObj = cbObj
  }

  toggleTapped() {
    const tappedNode = this.#findTappedNode()

    if (this.windowObj.selectingNode && (tappedNode === this.windowObj.selectingNode || tappedNode === undefined)) {
      // When tap the same node or non-node area
      this.#revertTapSelection()
      this.#setSelectingNode(null)
    } else {
      // When tap another node
      this.#applyTapSelection(tappedNode)
      this.#setSelectingNode(tappedNode)
      this.#setSelectedNode(tappedNode)
    }
  }

  toggleHovered() {
    const { selectedLayout, showingNodes } = this.#getShowingNodesAndSelectedLayout()
    const { closestNodeName, minmumDistance } = this.#findClosestNodeWithMinmumDistance(selectedLayout, showingNodes)

    if (closestNodeName && minmumDistance < 0.005) {
      // Emphasize nodes when find the closest node
      const connectedNodes = this.connections[closestNodeName] || []
      this.nodeSource.data["radius"] = this.#nodesIndex.map((nodeName) => {
        return nodeName === closestNodeName ? EMPTHASIS_SIZE : BASIC_SIZE
      })
      this.nodeSource.data["fill_color"] = this.#nodesIndex.map((nodeName) => {
        const isConnectedNode = nodeName === closestNodeName || (selectedLayout[nodeName] && connectedNodes.includes(nodeName))
        return isConnectedNode ? HIGHLIGHT_COLOR : BASIC_COLOR
      })
      this.edgeSource.data["line_color"] = this.#sourceNodes.map((start, i) => {
        return [start, this.#targetNodes[i]].includes(closestNodeName) ? HIGHLIGHT_COLOR : "gray"
      })
    } else {
      // Revert to default states
      this.nodeSource.data["radius"] = this.#nodesIndex.map(() => BASIC_SIZE)
      this.nodeSource.data["fill_color"] = this.#nodesIndex.map(() => BASIC_COLOR)
      this.edgeSource.data["line_color"] = this.#sourceNodes.map(() => "gray")
    }

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()
  }

  triggerZoom() {
    if (this.windowObj.selectingNode) { return }

    if (this.windowObj.zoomTimeout !== undefined) { clearTimeout(this.windowObj.zoomTimeout) }

    this.windowObj.zoomTimeout = setTimeout(() => { this.#handleZoom() }, 200)
  }

  resetPlot() {
    this.#setShiftX(0)
    this.#setShiftY(0)
    this.#setStableRange(undefined)
    this.#setDisplayChunksCount(0)
    this.#setSelectingNode(null)
    this.#setSelectedNode(null)
    this.#updateNodeXY(this.layoutsByChunk[0])

    this.nodeSource.data["alpha"] = this.#nodesIndex.map((nodeName) =>
      Object.keys(this.#selectedLayout).includes(nodeName) ? VISIBLE : TRANSLUCENT
    )
    this.nodeSource.change.emit()

    this.layoutProvider.graph_layout = this.layoutsByChunk[0]
    this.layoutProvider.change.emit()
  }

  #getShowingNodesAndSelectedLayout() {
    let selectedLayout
    let showingNodes

    if (this.windowObj.selectingNode) {
      selectedLayout = this.layoutsByChunk.slice(-1)[0]
      showingNodes = this.connections[this.windowObj.selectingNode] || []
      showingNodes.push(this.windowObj.selectingNode)
    } else {
      selectedLayout = this.#selectedLayout
      showingNodes = Object.keys(selectedLayout)
    }

    return { selectedLayout, showingNodes }
  }

  #findClosestNodeWithMinmumDistance(layout, showingNodes = null) {
    let closestNodeName
    let minmumDistance = Infinity

    const candidateNodes = showingNodes || Object.keys(layout)
    this.#nodesIndex.forEach((nodeName, i) => {
      if (!candidateNodes.includes(nodeName)) { return }

      const dx = layout[nodeName][0] + this.#shiftX - this.#mouseX
      const dy = layout[nodeName][1] + this.#shiftY - this.#mouseY
      const distance = dx * dx + dy * dy
      if (distance < minmumDistance) {
        minmumDistance = distance
        closestNodeName = this.#nodesIndex[i]
      }
    })
    return { closestNodeName, minmumDistance }
  }

  // @returns [nodesX[Array], nodesY[Array]]
  #updateNodeXY(layout) {
    const nodesX = this.nodeSource.data["x"]
    const nodesY = this.nodeSource.data["y"]
    this.#nodesIndex.forEach((nodeName, i) => {
      if (layout[nodeName]) {
        const [newX, newY] = layout[nodeName]
        nodesX[i] = newX
        nodesY[i] = newY
      }
    })
    return [nodesX, nodesY]
  }

  // @returns {string | undefined}
  #findTappedNode() {
    const currentDisplayNodes = this.windowObj.selectingNode ? this.connections[this.windowObj.selectingNode] : Object.keys(this.#selectedLayout)
    const selectedNodesIndices = this.cbObj.indices
    const tappedNodeIndex = selectedNodesIndices.find((id) => currentDisplayNodes.includes(this.#nodesIndex[id]))
    return tappedNodeIndex ? this.#nodesIndex[tappedNodeIndex] : undefined
  }

  #revertTapSelection() {
    const [nodesX, nodesY] = this.#updateNodeXY(this.#selectedLayout)
    this.#setShiftX(this.#mouseX - this.#selectedLayout[this.windowObj.selectedNode][0])
    this.#setShiftY(this.#mouseY - this.#selectedLayout[this.windowObj.selectedNode][1])

    this.#nodesIndex.forEach((nodeName, i) => {
      nodesX[i] += this.#shiftX
      nodesY[i] += this.#shiftY
      this.nodeSource.data["alpha"][i] = this.#selectedLayout[nodeName] ? VISIBLE : TRANSLUCENT
    })
    this.#sourceEdges.forEach((source, i) => {
      const target = this.#targetEdges[i]
      const displayEdge = this.#selectedLayout[source] && this.#selectedLayout[target]
      this.edgeSource.data["alpha"][i] = displayEdge ? VISIBLE : TRANSLUCENT
    })

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()

    const newGraphLayout = {}
    this.#nodesIndex.forEach((nodeName, i) => {
      newGraphLayout[nodeName] = [nodesX[i], nodesY[i]]
    })
    this.layoutProvider.graph_layout = newGraphLayout
    this.layoutProvider.change.emit()
  }

  #applyTapSelection(tappedNode) {
    const connectedNodes = [...(this.connections[tappedNode] || []), tappedNode]

    this.nodeSource.data["alpha"] = this.#nodesIndex.map((nodeName) =>
      connectedNodes.includes(nodeName) ? VISIBLE : TRANSLUCENT
    )
    this.edgeSource.data["alpha"] = this.#sourceEdges.map((sourceNode, i) =>
      connectedNodes.includes(sourceNode) && connectedNodes.includes(this.#targetEdges[i]) ? VISIBLE : TRANSLUCENT
    )

    const wholeLayout = this.layoutsByChunk.slice(-1)[0]
    const [nodesX, nodesY] = this.#updateNodeXY(wholeLayout)
    this.#setShiftX(this.#mouseX - wholeLayout[tappedNode][0])
    this.#setShiftY(this.#mouseY - wholeLayout[tappedNode][1])
    this.#nodesIndex.forEach((nodeName, i) => {
      nodesX[i] += this.#shiftX
      nodesY[i] += this.#shiftY
      wholeLayout[nodeName][0] += this.#shiftX
      wholeLayout[nodeName][1] += this.#shiftY
    })

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()

    this.layoutProvider.graph_layout = wholeLayout
    this.layoutProvider.change.emit()
  }

  #handleZoom() {
    const currentRange = this.cbObj.end - this.cbObj.start
    if (this.windowObj.stableRange === undefined) { this.#setStableRange(currentRange) }
    const previousDisplayChunksCount = this.#displayChunksCount
    const stableRange = this.windowObj.stableRange

    let displayChunksCount = this.#displayChunksCount

    // distance < 0: Zoom in
    // 0 < distance: Zoom out
    let distance = currentRange - stableRange
    const threshold = stableRange * 0.1
    if (Math.abs(distance) >= Math.abs(threshold)) {
      if (distance < 0) { // Zoom in
        displayChunksCount = Math.min(displayChunksCount + 1, this.chunkedNodes.length - 1)
      } else { // Zoom out
        displayChunksCount = Math.max(displayChunksCount - 1, 0)
      }
    }
    this.#setDisplayChunksCount(displayChunksCount)
    this.#setStableRange(currentRange)

    if (this.#displayChunksCount === previousDisplayChunksCount) { return }

    this.#nodesIndex.forEach((nodeName, i) => {
      this.nodeSource.data["alpha"][i] = this.#selectedLayout[nodeName] ? VISIBLE : TRANSLUCENT
    })

    this.#sourceEdges.forEach((source, i) => {
      const target = this.#targetEdges[i]
      const displayEdge = this.#selectedLayout[source] && this.#selectedLayout[target]
      this.edgeSource.data["alpha"][i] = displayEdge ? VISIBLE : TRANSLUCENT
    })

    const [nodesX, nodesY] = this.#updateNodeXY(this.#selectedLayout)
    const { closestNodeName } = this.#findClosestNodeWithMinmumDistance(this.layoutsByChunk[previousDisplayChunksCount])
    if (closestNodeName && this.#selectedLayout[closestNodeName]) {
      const closestNode = this.#selectedLayout[closestNodeName]
      this.#setShiftX(this.#mouseX - closestNode[0])
      this.#setShiftY(this.#mouseY - closestNode[1])
      this.#nodesIndex.forEach((_nodeName, i) => {
        nodesX[i] += this.#shiftX
        nodesY[i] += this.#shiftY
      })
    }

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()

    const shiftedLayout = {}
    this.#nodesIndex.forEach((nodeName, i) => {
      shiftedLayout[nodeName] = [nodesX[i], nodesY[i]]
    })
    this.layoutProvider.graph_layout = shiftedLayout
    this.layoutProvider.change.emit()
  }

  get #mouseX() { return this.cbObj.x || this.windowObj.lastMouseX || 0 }
  get #mouseY() { return this.cbObj.y || this.windowObj.lastMouseY || 0 }
  get #shiftX() { return this.windowObj.previousShiftX || 0 }
  get #shiftY() { return this.windowObj.previousShiftY || 0 }
  get #nodesIndex() { return this.nodeSource.data["index"] }
  get #sourceNodes() { return this.edgeSource.data["start"] }
  get #targetNodes() { return this.edgeSource.data["end"] }
  get #sourceEdges() { return this.edgeSource.data["start"] }
  get #targetEdges() { return this.edgeSource.data["end"] }
  get #displayChunksCount() {
    if (this.windowObj.displayChunksCount === undefined) { this.#setDisplayChunksCount(0) }
    return this.windowObj.displayChunksCount || 0
  }
  get #selectedLayout() {
    const layout = this.layoutsByChunk[this.#displayChunksCount]
    if (this.windowObj.selectedNode) {
      layout[this.windowObj.selectedNode] = this.layoutsByChunk.slice(-1)[0][this.windowObj.selectedNode]
    }
    return layout
  }
  // @param {Integer} value
  #setDisplayChunksCount(value) { this.windowObj.displayChunksCount = value }
  // @param {Float} value
  #setStableRange(value) { this.windowObj.stableRange = value }
  // @param {Float} value
  #setShiftX(value) { this.windowObj.previousShiftX = value }
  // @param {Float} value
  #setShiftY(value) { this.windowObj.previousShiftY = value }
  // @param { String } value
  #setSelectingNode(value) { this.windowObj.selectingNode = value }
  // @param {String} nodeName
  #setSelectedNode(nodeName) { this.windowObj.selectedNode = nodeName }
}

const graphManager = new GraphManager({
  graphRenderer,
  layoutProvider,
  connectionsData,
  layoutsByChunkData,
  chunkedNodesData,
  windowObj: window,
  cbObj: cb_obj,
})
