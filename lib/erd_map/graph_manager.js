class GraphManager {
  constructor({
    graphRenderer,
    rectRenderer,
    circleRenderer,
    layoutProvider,
    connectionsData,
    layoutsByChunkData,
    chunkedNodesData,
    nodeWithCommunityIndexData,
    selectingNodeLabel,
    zoomModeToggle,
    tapModeToggle,
    displayTitleModeToggle,
    nodeLabels,
    plot,
    windowObj,
  }) {
    this.graphRenderer = graphRenderer
    this.rectRenderer = rectRenderer
    this.circleRenderer = circleRenderer
    this.nodeSource = this.graphRenderer.node_renderer.data_source
    this.edgeSource = this.graphRenderer.edge_renderer.data_source
    this.cardinalityDataSource = cardinalityDataSource
    this.layoutProvider = layoutProvider
    this.connections = JSON.parse(connectionsData)
    this.layoutsByChunk = JSON.parse(layoutsByChunkData)
    this.chunkedNodes = JSON.parse(chunkedNodesData)
    this.nodeWithCommunityIndex = JSON.parse(nodeWithCommunityIndexData)
    this.selectingNodeLabel = selectingNodeLabel
    this.zoomModeToggle = zoomModeToggle
    this.tapModeToggle = tapModeToggle
    this.displayTitleModeToggle = displayTitleModeToggle
    this.nodeLabels = nodeLabels
    this.plot = plot
    this.windowObj = windowObj
    this.cbObj = cb_obj

    this.#addNodeLabelsWithDelay()
    this.resetPlot()
  }

  toggleTapped() {
    this.#resetSearch()
    const tappedNode = this.#findTappedNode()
    this.#applyTap(tappedNode, { nodeTapped: true })
  }

  toggleHovered() {
    const { selectedLayout, showingNodes } = this.#getShowingNodesAndSelectedLayout()
    const { closestNodeName, minmumDistance } = this.#findClosestNodeWithMinmumDistance(selectedLayout, showingNodes)

    const originalColors = this.#showTitleMode ? this.nodeSource.data["circle_original_color"] : this.nodeSource.data["rect_original_color"]
    const originalRadius = this.nodeSource.data["original_radius"]

    if (closestNodeName && minmumDistance < 0.005) {
      // Emphasize nodes when find the closest node
      const connectedNodes = (this.connections[closestNodeName] || []).concat([closestNodeName])
      this.#nodesIndex.forEach((nodeName, i) => {
        const isConnectedNode = selectedLayout[nodeName] && connectedNodes.includes(nodeName)
        this.nodeSource.data["text_color"][i] = isConnectedNode ? HIGHLIGHT_TEXT_COLOR : BASIC_COLOR
        this.nodeSource.data["text_outline_color"][i] = isConnectedNode ? BASIC_COLOR : null
      })
      this.nodeSource.data["fill_color"] = this.#nodesIndex.map((nodeName, i) => {
        const isConnectedNode = selectedLayout[nodeName] && connectedNodes.includes(nodeName)
        return isConnectedNode ? HIGHLIGHT_NODE_COLOR : originalColors[i]
      })
      this.nodeSource.data["radius"] = this.#nodesIndex.map((nodeName, i) => {
        return nodeName === closestNodeName ? EMPTHASIS_NODE_SIZE : originalRadius[i]
      })
      this.edgeSource.data["line_color"] = this.#sourceNodes.map((start, i) => {
        return [start, this.#targetNodes[i]].includes(closestNodeName) ? HIGHLIGHT_EDGE_COLOR : BASIC_COLOR
      })
      this.cardinalityDataSource.data["text_color"] = this.cardinalityDataSource.data["source"].map((sourceNodeName, i) => {
        const targetNodeName = this.cardinalityDataSource.data["target"][i]
        const isConnectedNode = (closestNodeName === sourceNodeName || closestNodeName === targetNodeName) &&
          (selectedLayout[sourceNodeName] && connectedNodes.includes(sourceNodeName)) &&
          (selectedLayout[targetNodeName] && connectedNodes.includes(targetNodeName))
        return isConnectedNode ? HIGHLIGHT_EDGE_COLOR : BASIC_COLOR
      })
    } else {
      // Revert to default states
      this.nodeSource.data["radius"] = originalRadius
      this.nodeSource.data["fill_color"] = originalColors
      this.nodeSource.data["text_color"] = this.#nodesIndex.map(() => BASIC_COLOR)
      this.nodeSource.data["text_outline_color"] = this.#nodesIndex.map(() => null)
      this.edgeSource.data["line_color"] = this.#sourceNodes.map(() => BASIC_COLOR)
      this.cardinalityDataSource.data["text_color"] = this.cardinalityDataSource.data["text_color"].map(() => BASIC_COLOR)
    }

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()
    this.cardinalityDataSource.change.emit()
  }

  triggerZoom() {
    if (this.#fixingZoom) { return }

    if (this.windowObj.zoomTimeout !== undefined) { clearTimeout(this.windowObj.zoomTimeout) }

    this.windowObj.zoomTimeout = setTimeout(() => { this.#handleZoom() }, 200)
  }

  zoomIn() {
    const displayChunksCount = Math.min(this.#displayChunksCount + 1, this.chunkedNodes.length - 1)
    this.#setDisplayChunksCount(displayChunksCount)
    this.#executeZoom({ previousDisplayChunksCount: null })
  }

  zoomOut() {
    const displayChunksCount = Math.max(this.#displayChunksCount - 1, 0)
    this.#setDisplayChunksCount(displayChunksCount)
    this.#executeZoom({ previousDisplayChunksCount: null })
  }

  toggleZoomMode() {
    this.#setFixingZoom(!this.#fixingZoom)

    if (this.#fixingZoom) {
      this.zoomModeToggle.label = "Wheel mode: fix"
      this.zoomModeToggle.button_type = "default"
    } else {
      this.zoomModeToggle.label = "Wheel mode: zoom"
      this.zoomModeToggle.button_type = "warning"
      this.#setSelectingNodeLabel(null)
      this.selectingNodeLabel.change.emit()
    }
  }

  toggleTapMode() {
    if (this.#showingAssociation) {
      this.tapModeToggle.label = "Tap mode: community"
      this.tapModeToggle.button_type = "warning"
    } else {
      this.tapModeToggle.label = "Tap mode: association"
      this.tapModeToggle.button_type = "default"
    }
    this.#setShowingAssociation(!this.#showingAssociation)
    if (this.windowObj.selectingNode) {
      this.#applyTap(this.windowObj.selectingNode, { nodeTapped: false })
    }
  }

  toggleDisplayTitleMode() {
    this.#setShowTitleMode(!this.#showTitleMode)
    this.rectRenderer.visible = !this.#showTitleMode
    this.circleRenderer.visible = this.#showTitleMode
    this.#applyDisplayTitleMode()
  }

  reLayout() {
    const minMax = {
      minX: this.plot.x_range.start,
      maxX: this.plot.x_range.end,
      minY: this.plot.y_range.start,
      maxY: this.plot.y_range.end,
      isInsideDisplay(x, y) { return this.minX <= x && x <= this.maxX && this.minY <= y && y <= this.maxY },
      randXY() {
        return [
          this.minX + Math.random() * (this.maxX - this.minX), // randX
          this.minY + Math.random() * (this.maxY - this.minY), // randY
        ]
      },
      distances() {
        const averageRange = ((this.maxX - this.minX) + (this.maxY - this.minY)) / 2
        return [
          averageRange * 0.25, //minDistance
          averageRange * 0.5, // maxDistance
        ]
      }
    }
    const placedPositions = []
    const { showingNodes, selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    const newLayout = { ...selectedLayout }
    showingNodes.forEach((nodeName) => {
      const [currentX, currentY] = newLayout[nodeName] || this.#wholeLayout[nodeName]
      if (minMax.isInsideDisplay(currentX, currentY)) {
        const [newX, newY] = this.#findReLayoutXY(placedPositions, minMax)
        newLayout[nodeName] = [newX, newY]
        placedPositions.push([newX, newY])
      }
    })

    this.#setShiftX(0)
    this.#setShiftY(0)
    this.#updateLayout(newLayout, null)
    this.layoutProvider.graph_layout = newLayout
    this.layoutProvider.change.emit()
  }

  searchNodes() {
    this.#setSearchingTerm(searchBox.value.trim().toLowerCase().replaceAll("_", ""))
    if (!this.#searchingTerm) { return this.#resetSearch() }

    const { showingNodes, selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.#changeDisplayNodes(showingNodes)

    this.layoutProvider.graph_layout = selectedLayout
    this.layoutProvider.change.emit()

    this.#setSelectingNodeLabel(this.#searchingTerm)
    this.selectingNodeLabel.change.emit()
  }

  #applyTap(tappedNode, { nodeTapped }) {
    if (this.#showingAssociation) {
      if (this.windowObj.selectingNode === undefined && tappedNode === undefined) {
        // When tap non-node area with non-selecting mode
        // do nothing
      } else if (nodeTapped && this.windowObj.selectingNode && (tappedNode === this.windowObj.selectingNode || tappedNode === undefined)) {
        // When tap the same node or non-node area
        this.#setSelectingNode(null)
        this.#revertTapSelection()
      } else {
        // When tap new or another node
        this.#setSelectingNode(tappedNode)
        this.#setSelectedNode(tappedNode)
        this.#applyTapSelection(tappedNode)
      }
    } else {
      this.#setSelectingNode(tappedNode)
      this.#setSelectedNode(tappedNode)
      const { showingNodes } = this.#getShowingNodesAndSelectedLayout()
      this.#changeDisplayNodes(showingNodes)
    }
    this.#setSelectingNodeLabel(this.windowObj.selectingNode)
    this.selectingNodeLabel.change.emit()
  }

  resetPlot() {
    this.#setShiftX(0)
    this.#setShiftY(0)
    this.#setStableRange(undefined)
    this.#setDisplayChunksCount(0)
    this.#setSelectingNode(null)
    this.#setSelectedNode(null)
    this.#setFixingZoom(!true) // Set the opposite value of toggled value
    this.toggleZoomMode()
    this.#resetSearch()

    if (this.#showingAssociation === false) { this.toggleTapMode() }
    if (this.#showTitleMode === false) { this.toggleDisplayTitleMode() }

    const { showingNodes, selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.#changeDisplayNodes(showingNodes)

    this.#updateLayout(this.layoutsByChunk[0])
    const newLayout = { ...selectedLayout }
    this.#nodesIndex.forEach((nodeName, i) => {
      if (newLayout[nodeName] === undefined) {
        newLayout[nodeName] = this.#wholeLayout[nodeName]
      }
    })
    this.layoutProvider.graph_layout = newLayout
    this.layoutProvider.change.emit()
  }

  #getShowingNodesAndSelectedLayout() {
    let selectedLayout = this.#selectedLayout
    let showingNodes = Object.keys(selectedLayout)

    if (this.windowObj.selectingNode && this.#showingAssociation) {
      selectedLayout = this.#wholeLayout
      showingNodes = this.connections[this.windowObj.selectingNode] || []
      showingNodes.push(this.windowObj.selectingNode)
    } else if (this.windowObj.selectingNode) {
      selectedLayout = this.#wholeLayout
      const communityIndex = this.nodeWithCommunityIndex[this.windowObj.selectingNode]
      showingNodes = Object.keys(this.nodeWithCommunityIndex).filter(node => this.nodeWithCommunityIndex[node] === communityIndex)
      showingNodes.push(this.windowObj.selectingNode)
    }
    if (this.#searchingTerm) {
      selectedLayout = this.#wholeLayout
      showingNodes.forEach(nodeName => {
        if (this.#selectedLayout[nodeName]) {
          selectedLayout[nodeName] = this.#selectedLayout[nodeName]
        }
      })
      const matchedNodes = this.#nodesIndex.filter(nodeName =>
        nodeName.toLowerCase().includes(this.#searchingTerm)
      )
      showingNodes = showingNodes.concat(matchedNodes)
    }

    return { selectedLayout, showingNodes }
  }

  #findClosestNodeWithMinmumDistance(layout, candidateNodes) {
    let closestNodeName
    let minmumDistance = Infinity

    this.#nodesIndex.forEach((nodeName, i) => {
      if (!candidateNodes.includes(nodeName)) { return }

      const xy = layout[nodeName] || this.#wholeLayout[nodeName]
      const dx = xy[0] - this.#mouseX
      const dy = xy[1] - this.#mouseY
      const distance = dx * dx + dy * dy
      if (distance < minmumDistance) {
        minmumDistance = distance
        closestNodeName = this.#nodesIndex[i]
      }
    })
    return { closestNodeName, minmumDistance }
  }

  #changeDisplayNodes(showingNodes) {
    this.nodeSource.data["alpha"] = this.#nodesIndex.map((nodeName) =>
      showingNodes.includes(nodeName) ? VISIBLE : TRANSLUCENT
    )
    this.edgeSource.data["alpha"] = this.#sourceEdges.map((source, i) =>
      showingNodes.includes(source) && showingNodes.includes(this.edgeSource.data["end"][i]) ? VISIBLE : TRANSLUCENT
    )
    this.cardinalityDataSource.data["alpha"] = this.cardinalityDataSource.data["source"].map((sourceNodeName, i) => {
      const targetNodeName = this.cardinalityDataSource.data["target"][i]

      if (showingNodes.includes(sourceNodeName) && showingNodes.includes(targetNodeName) && sourceNodeName !== targetNodeName) {
        return VISIBLE
      } else {
        return 0
      }
    })

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()
    this.cardinalityDataSource.change.emit()
    this.#applyDisplayTitleMode()
  }

  // @returns [nodesX[Array], nodesY[Array]]
  #updateLayout(layout, centerNodeName) {
    const nodesX = this.nodeSource.data["x"]
    const nodesY = this.nodeSource.data["y"]
    const applyShift = !!layout[centerNodeName]
    if (applyShift) {
      this.#setShiftX(this.#mouseX - layout[centerNodeName][0])
      this.#setShiftY(this.#mouseY - layout[centerNodeName][1])
    }
    const shiftX = this.#shiftX
    const shiftY = this.#shiftY
    this.#nodesIndex.forEach((nodeName, i) => {
      const [newX, newY] = layout[nodeName] || this.#wholeLayout[nodeName]
      nodesX[i] = newX + shiftX
      nodesY[i] = newY + shiftY
    })

    const cardinalityOffsetX = 0.2
    const cardinalityOffsetY = 0.3
    this.cardinalityDataSource.data["x"].forEach((_, i) => {
      const sourceNodeName = this.cardinalityDataSource.data["source"][i]
      const targetNodeName = this.cardinalityDataSource.data["target"][i]

      const sourceLayout = layout[sourceNodeName] || this.#wholeLayout[sourceNodeName]
      const targetLayout = layout[targetNodeName] || this.#wholeLayout[targetNodeName]

      const sourceX = sourceLayout[0] + shiftX
      const sourceY = sourceLayout[1] + shiftY
      const targetX = targetLayout[0] + shiftX
      const targetY = targetLayout[1] + shiftY
      const vectorX = targetX - sourceX
      const vectorY = targetY - sourceY
      const length = Math.sqrt(vectorX * vectorX + vectorY * vectorY)

      const isSourceNode = i % 2 === 0
      this.cardinalityDataSource.data["x"][i] = isSourceNode ?
        sourceX + (vectorX / length) * cardinalityOffsetX
        : targetX - (vectorX / length) * cardinalityOffsetX
      this.cardinalityDataSource.data["y"][i] = isSourceNode ?
        sourceY + (vectorY / length) * cardinalityOffsetY
        : targetY - (vectorY / length) * cardinalityOffsetY
    })

    this.nodeSource.change.emit()
    this.edgeSource.change.emit()
    this.cardinalityDataSource.change.emit()

    return [nodesX, nodesY]
  }

  // @returns {string | undefined}
  #findTappedNode() {
    const { showingNodes } = this.#getShowingNodesAndSelectedLayout()
    const selectedNodesIndices = this.cbObj.indices
    const tappedNodeIndex = selectedNodesIndices.find((id) => showingNodes.includes(this.#nodesIndex[id]))
    return tappedNodeIndex ? this.#nodesIndex[tappedNodeIndex] : undefined
  }

  #revertTapSelection() {
    const { showingNodes, selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.#changeDisplayNodes(showingNodes)

    const [nodesX, nodesY] = this.#updateLayout(selectedLayout, this.windowObj.selectedNode)
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
    this.#changeDisplayNodes(connectedNodes)

    const { selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    const [nodesX, nodesY] = this.#updateLayout(selectedLayout, tappedNode)
    this.#nodesIndex.forEach((nodeName, i) => {
      selectedLayout[nodeName][0] = nodesX[i]
      selectedLayout[nodeName][1] = nodesY[i]
    })
    this.layoutProvider.graph_layout = selectedLayout
    this.layoutProvider.change.emit()
  }

  #addNodeLabelsWithDelay() {
    // Wait a sec because errors occur if we call add_layout multitime once
    this.plot.add_layout(this.nodeLabels.titleModelLabel)
    setTimeout(() => {
      this.plot.add_layout(this.nodeLabels.foreignModelLabel)
      setTimeout(() => {
        this.plot.add_layout(this.nodeLabels.foreignColumnsLabel)
      }, 100)
    }, 100)
  }

  #applyDisplayTitleMode() {
    this.nodeLabels.foreignModelLabel.visible = !this.#showTitleMode
    this.nodeLabels.foreignColumnsLabel.visible = !this.#showTitleMode
    this.nodeLabels.titleModelLabel.visible = this.#showTitleMode

    if (this.#showTitleMode) {
      this.displayTitleModeToggle.label = "Display mode: title"
      this.circleRenderer.node_renderer.data_source.data["fill_color"] = this.nodeSource.data["circle_original_color"]
      this.circleRenderer.node_renderer.data_source.data["alpha"] = this.nodeSource.data["alpha"]
      this.circleRenderer.edge_renderer.data_source.data["alpha"] = this.edgeSource.data["alpha"]
      this.circleRenderer.node_renderer.data_source.change.emit()
      this.circleRenderer.edge_renderer.data_source.change.emit()
    } else {
      this.displayTitleModeToggle.label = "Display mode: foreign key"
      this.rectRenderer.node_renderer.data_source.data["fill_color"] = this.nodeSource.data["rect_original_color"]
      this.rectRenderer.node_renderer.data_source.data["alpha"] = this.nodeSource.data["alpha"]
      this.rectRenderer.edge_renderer.data_source.data["alpha"] = this.edgeSource.data["alpha"]
      this.rectRenderer.node_renderer.data_source.change.emit()
      this.rectRenderer.edge_renderer.data_source.change.emit()
    }
  }

  #findReLayoutXY(placedPositions, minMax) {
    const maxAttemptCount = 100
    const [minDistance, maxDistance] = minMax.distances()
    for (let t = 0; t < maxAttemptCount; t++) {
      const [randX, randY] = minMax.randXY()
      const ngPosition = placedPositions.some(([existX, existY]) => {
        const distanceX = existX - randX
        const distanceY = existY - randY
        const distance = Math.sqrt(distanceX * distanceX + distanceY * distanceY)
        return distance < minDistance || distance > maxDistance
      })
      if (!ngPosition) { return [randX, randY] }
    }
    return minMax.randXY()
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

    this.#resetSearch()
    this.#setSelectingNode(null)
    this.#setSelectingNodeLabel(null)
    this.selectingNodeLabel.change.emit()

    const { showingNodes, selectedLayout } = this.#getShowingNodesAndSelectedLayout()
    this.#changeDisplayNodes(showingNodes)

    let closestNodeName
    if (previousDisplayChunksCount === null) {
      closestNodeName = null
    } else {
      // Find the closest node (to shift XY with updateLayout) only when have previousDisplayChunksCount
      const showingNodes = [...Object.keys(this.layoutsByChunk[previousDisplayChunksCount]), this.windowObj.selectedNode].filter(node => node)
      const closestNodeWithMinmumDistance = this.#findClosestNodeWithMinmumDistance(this.layoutsByChunk[previousDisplayChunksCount], showingNodes)
      closestNodeName = closestNodeWithMinmumDistance['closestNodeName']
    }

    const [nodesX, nodesY] = this.#updateLayout(selectedLayout, closestNodeName)
    const shiftedLayout = {}
    this.#nodesIndex.forEach((nodeName, i) => {
      shiftedLayout[nodeName] = [nodesX[i], nodesY[i]]
    })
    this.layoutProvider.graph_layout = shiftedLayout
    this.layoutProvider.change.emit()
  }

  #resetSearch() {
    this.#setSearchingTerm(null)

    this.#setSelectingNodeLabel(null)
    this.selectingNodeLabel.change.emit()

    searchBox.value = ""
  }

  get #mouseX() { return this.cbObj.x || this.windowObj.lastMouseX || 0 }
  get #mouseY() { return this.cbObj.y || this.windowObj.lastMouseY || 0 }
  get #shiftX() { return this.windowObj.previousShiftX || 0 }
  get #shiftY() { return this.windowObj.previousShiftY || 0 }
  get #nodesIndex() { return this.nodeSource.data["index"] }
  get #sourceNodes() { return this.edgeSource.data["start"] }
  get #targetNodes() { return this.edgeSource.data["end"] }
  get #sourceEdges() { return this.edgeSource.data["start"] }
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
    if (this.windowObj.fixingZoom === undefined) { this.#setFixingZoom(true) }
    return this.windowObj.fixingZoom
  }
  get #showingAssociation() {
    if (this.windowObj.showingAssociation === undefined) { this.#setShowingAssociation(true) }
    return this.windowObj.showingAssociation
  }
  get #searchingTerm() { return this.windowObj.searchingTerm }
  get #showTitleMode() {
    if (this.windowObj.showTitleMode === undefined) { this.#setShowTitleMode(true) }
    return this.windowObj.showTitleMode
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
  #setSelectingNodeLabel(value) {
    if (value) {
      const mode = this.#showingAssociation ? "associations" : "community"
      this.selectingNodeLabel.text = this.#searchingTerm ? `Searching: ${value}` : `Showing: ${value}'s ${mode}`
    } else {
      this.selectingNodeLabel.text = ""
    }
  }
  // @param {String} value
  #setSearchingTerm(value) { this.windowObj.searchingTerm = value }
  // @param {Boolean} value
  #setShowingAssociation(value) { this.windowObj.showingAssociation = value }
  // @param {Boolean} value
  #setShowTitleMode(value) { this.windowObj.showTitleMode = value }
}
