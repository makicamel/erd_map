class GraphManager {
  constructor({
    graphRenderer,
    layoutProvider,
    connectionsData,
    layoutsByChunkData,
    chunkedNodesData,
    zoomModeToggle,
    selectingNodeLabel,
    windowObj,
    cbObj,
  }) {
    this.nodeSource = graphRenderer.node_renderer.data_source
    this.edgeSource = graphRenderer.edge_renderer.data_source
    this.layoutProvider = layoutProvider
    this.connections = JSON.parse(connectionsData)
    this.layoutsByChunk = JSON.parse(layoutsByChunkData)
    this.chunkedNodes = JSON.parse(chunkedNodesData)
    this.zoomModeToggle = zoomModeToggle
    this.selectingNodeLabel = selectingNodeLabel
    this.windowObj = windowObj
    this.cbObj = cbObj
  }

  toggleTapped() {
    const tappedNode = this.#findTappedNode()

    if (this.windowObj.selectingNode === undefined && tappedNode === undefined) {
      // When tap non-node area with non-selecting mode
      // do nothing
    } else if (this.windowObj.selectingNode && (tappedNode === this.windowObj.selectingNode || tappedNode === undefined)) {
      // When tap the same node or non-node area
      this.#setSelectingNode(null)
      this.#revertTapSelection()
      this.#setFixingZoom(!false) // Set the opposite value of toggled value
      this.toggleZoomMode()
    } else {
      // When tap another node
      this.#setSelectingNode(tappedNode)
      this.#setSelectedNode(tappedNode)
      this.#applyTapSelection(tappedNode)
      this.#setFixingZoom(!true) // Set the opposite value of toggled value
      this.toggleZoomMode()
    }

    this.#setSelectingNodeLabel(this.windowObj.selectingNode)
    this.selectingNodeLabel.change.emit()
  }

  toggleHovered() {
    const { selectedLayout, showingNodes } = this.#getShowingNodesAndSelectedLayout()
    const { closestNodeName, minmumDistance } = this.#findClosestNodeWithMinmumDistance(selectedLayout, showingNodes)

    const originalColors = this.nodeSource.data["original_color"]
    const originalRadius = this.nodeSource.data["original_radius"]

    if (closestNodeName && minmumDistance < 0.005) {
      // Emphasize nodes when find the closest node
      const connectedNodes = this.connections[closestNodeName] || []
      this.#nodesIndex.forEach((nodeName, i) => {
        const isConnectedNode = nodeName === closestNodeName || (selectedLayout[nodeName] && connectedNodes.includes(nodeName))
        this.nodeSource.data["text_color"][i] = isConnectedNode ? HIGHLIGHT_TEXT_COLOR : BASIC_COLOR
        this.nodeSource.data["text_outline_color"][i] = isConnectedNode ? BASIC_COLOR : null
      })
      this.nodeSource.data["fill_color"] = this.#nodesIndex.map((nodeName, i) => {
        const isConnectedNode = nodeName === closestNodeName || (selectedLayout[nodeName] && connectedNodes.includes(nodeName))
        return isConnectedNode ? HIGHLIGHT_NODE_COLOR : originalColors[i]
      })
      this.nodeSource.data["radius"] = this.#nodesIndex.map((nodeName, i) => {
        return nodeName === closestNodeName ? EMPTHASIS_NODE_SIZE : originalRadius[i]
      })
      this.edgeSource.data["line_color"] = this.#sourceNodes.map((start, i) => {
        return [start, this.#targetNodes[i]].includes(closestNodeName) ? HIGHLIGHT_EDGE_COLOR : BASIC_COLOR
      })
    } else {
      // Revert to default states
      this.nodeSource.data["radius"] = originalRadius
      this.nodeSource.data["fill_color"] = originalColors
      this.nodeSource.data["text_color"] = this.#nodesIndex.map(() => BASIC_COLOR)
      this.nodeSource.data["text_outline_color"] = this.#nodesIndex.map(() => null)
      this.edgeSource.data["line_color"] = this.#sourceNodes.map(() => BASIC_COLOR)
    }

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()
  }

  triggerZoom() {
    if (this.#fixingZoom) { return }

    if (this.windowObj.zoomTimeout !== undefined) { clearTimeout(this.windowObj.zoomTimeout) }

    this.windowObj.zoomTimeout = setTimeout(() => { this.#handleZoom() }, 200)
  }

  zoomIn() {
    const displayChunksCount = Math.min(this.#displayChunksCount + 1, this.chunkedNodes.length - 1)
    this.#setDisplayChunksCount(displayChunksCount)
    if (this.#fixingZoom) { this.toggleZoomMode() }
    this.#executeZoom({ previousDisplayChunksCount: null })
  }

  zoomOut() {
    const displayChunksCount = Math.max(this.#displayChunksCount - 1, 0)
    this.#setDisplayChunksCount(displayChunksCount)
    if (this.#fixingZoom) { this.toggleZoomMode() }
    this.#executeZoom({ previousDisplayChunksCount: null })
  }

  toggleZoomMode() {
    this.#setFixingZoom(!this.#fixingZoom)

    if (this.#fixingZoom) {
      this.zoomModeToggle.label = "Fixing Zoom"
      this.zoomModeToggle.button_type = "danger"
    } else {
      this.zoomModeToggle.label = "Zooming"
      this.zoomModeToggle.button_type = "warning"
      this.#setSelectingNodeLabel(null)
      this.selectingNodeLabel.change.emit()
    }
  }

  resetPlot() {
    this.#setShiftX(0)
    this.#setShiftY(0)
    this.#setStableRange(undefined)
    this.#setDisplayChunksCount(0)
    this.#setSelectingNode(null)
    this.#setSelectedNode(null)
    this.#updateNodeXY(this.layoutsByChunk[0])
    this.#setFixingZoom(!false) // Set the opposite value of toggled value
    this.toggleZoomMode()

    const { selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.nodeSource.data["alpha"] = this.#nodesIndex.map((nodeName) => {
      return selectedLayout[nodeName] ? VISIBLE : TRANSLUCENT
    })
    this.edgeSource.data["alpha"] = this.#sourceEdges.map((source, i) => {
      const target = this.#targetEdges[i]
      const displayEdge = selectedLayout[source] && selectedLayout[target]
      return displayEdge ? VISIBLE : TRANSLUCENT
    })
    this.nodeSource.change.emit()
    this.edgeSource.change.emit()

    this.layoutProvider.graph_layout = selectedLayout
    this.layoutProvider.change.emit()
  }

  #getShowingNodesAndSelectedLayout() {
    let selectedLayout
    let showingNodes

    if (this.windowObj.selectingNode) {
      selectedLayout = this.#wholeLayout
      showingNodes = this.connections[this.windowObj.selectingNode] || []
      showingNodes.push(this.windowObj.selectingNode)
    } else {
      selectedLayout = this.#selectedLayout
      showingNodes = Object.keys(selectedLayout)
    }

    return { selectedLayout, showingNodes }
  }

  #findClosestNodeWithMinmumDistance(layout, candidateNodes) {
    let closestNodeName
    let minmumDistance = Infinity

    this.#nodesIndex.forEach((nodeName, i) => {
      if (!candidateNodes.includes(nodeName)) { return }

      const xy = layout[nodeName] || this.#wholeLayout[nodeName]
      const dx = xy[0] + this.#shiftX - this.#mouseX
      const dy = xy[1] + this.#shiftY - this.#mouseY
      const distance = dx * dx + dy * dy
      if (distance < minmumDistance) {
        minmumDistance = distance
        closestNodeName = this.#nodesIndex[i]
      }
    })
    return { closestNodeName, minmumDistance }
  }

  // @returns [nodesX[Array], nodesY[Array]]
  #updateNodeXY(layout, centerNodeName) {
    const nodesX = this.nodeSource.data["x"]
    const nodesY = this.nodeSource.data["y"]
    const applyShift = !!layout[centerNodeName]
    if (applyShift) {
      this.#setShiftX(this.#mouseX - layout[centerNodeName][0])
      this.#setShiftY(this.#mouseY - layout[centerNodeName][1])
      this.#nodesIndex.forEach((nodeName, i) => {
        const [newX, newY] = layout[nodeName] || this.#wholeLayout[nodeName]
        nodesX[i] = newX + this.#shiftX
        nodesY[i] = newY + this.#shiftY
      })
    } else {
      this.#nodesIndex.forEach((nodeName, i) => {
        const [newX, newY] = layout[nodeName] || this.#wholeLayout[nodeName]
        nodesX[i] = newX + this.#shiftX
        nodesY[i] = newY + this.#shiftY
      })
    }

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
    const { selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    const [nodesX, nodesY] = this.#updateNodeXY(selectedLayout, this.windowObj.selectedNode)
    this.#nodesIndex.forEach((nodeName, i) => {
      this.nodeSource.data["alpha"][i] = selectedLayout[nodeName] ? VISIBLE : TRANSLUCENT
    })
    this.#sourceEdges.forEach((source, i) => {
      const target = this.#targetEdges[i]
      const displayEdge = selectedLayout[source] && selectedLayout[target]
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
    if (tappedNode === undefined) { return }

    const connectedNodes = [...(this.connections[tappedNode] || []), tappedNode]

    this.nodeSource.data["alpha"] = this.#nodesIndex.map((nodeName) =>
      connectedNodes.includes(nodeName) ? VISIBLE : TRANSLUCENT
    )
    this.edgeSource.data["alpha"] = this.#sourceEdges.map((sourceNode, i) =>
      connectedNodes.includes(sourceNode) && connectedNodes.includes(this.#targetEdges[i]) ? VISIBLE : TRANSLUCENT
    )

    const { selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.#updateNodeXY(selectedLayout, tappedNode)
    this.#nodesIndex.forEach(nodeName => {
      selectedLayout[nodeName][0] += this.#shiftX
      selectedLayout[nodeName][1] += this.#shiftY
    })

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()

    this.layoutProvider.graph_layout = selectedLayout
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
    this.#executeZoom({ previousDisplayChunksCount })
  }

  #executeZoom({ previousDisplayChunksCount }) {
    if (this.#displayChunksCount === previousDisplayChunksCount) { return }

    this.#setSelectingNode(null)
    const { selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.nodeSource.data["alpha"] = this.#nodesIndex.map((nodeName) => {
      return selectedLayout[nodeName] ? VISIBLE : TRANSLUCENT
    })

    this.edgeSource.data["alpha"] = this.#sourceEdges.map((source, i) => {
      const target = this.#targetEdges[i]
      const displayEdge = selectedLayout[source] && selectedLayout[target]
      return displayEdge ? VISIBLE : TRANSLUCENT
    })

    let closestNodeName
    if (previousDisplayChunksCount === null) {
      closestNodeName = null
    } else {
      // Find the closest node (to shift XY with updateNodeXY) only when have previousDisplayChunksCount
      const showingNodes = [...Object.keys(this.layoutsByChunk[previousDisplayChunksCount]), this.windowObj.selectedNode].filter(node => node)
      const closestNodeWithMinmumDistance = this.#findClosestNodeWithMinmumDistance(this.layoutsByChunk[previousDisplayChunksCount], showingNodes)
      closestNodeName = closestNodeWithMinmumDistance['closestNodeName']
    }
    const [nodesX, nodesY] = this.#updateNodeXY(selectedLayout, closestNodeName)

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
      layout[this.windowObj.selectedNode] = this.#wholeLayout[this.windowObj.selectedNode]
    }
    return layout
  }
  get #wholeLayout() { return this.layoutsByChunk.slice(-1)[0] }
  get #fixingZoom() {
    if (this.windowObj.fixingZoom === undefined) { this.#setFixingZoom(false) }
    return this.windowObj.fixingZoom
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
  // @param {Boolean} value
  #setFixingZoom(value) { this.windowObj.fixingZoom = value }
  // @param {String | null} value
  #setSelectingNodeLabel(value) { this.selectingNodeLabel.text = value ? `Showing: ${value}'s associations` : "" }
}

const graphManager = new GraphManager({
  graphRenderer,
  layoutProvider,
  connectionsData,
  layoutsByChunkData,
  chunkedNodesData,
  zoomModeToggle,
  selectingNodeLabel,
  windowObj: window,
  cbObj: cb_obj,
})
