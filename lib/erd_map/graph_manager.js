class GraphManager {
  constructor({
    graphRenderer,
    connectionsData,
    layoutsByChunkData,
    windowObj,
    cbObj,
  }) {
    this.nodeSource = graphRenderer.node_renderer.data_source
    this.edgeSource = graphRenderer.edge_renderer.data_source
    this.connections = JSON.parse(connectionsData)
    this.layoutsByChunk = JSON.parse(layoutsByChunkData)
    this.windowObj = windowObj
    this.cbObj = cbObj
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
    return { closestNodeName: closestNodeName, minmumDistance: minmumDistance }
  }

  #getShowingNodesAndSelectedLayout() {
    let selectedLayout
    let showingNodes

    if (this.windowObj.selectingNode) {
      selectedLayout = this.layoutsByChunk.slice(-1)[0]
      showingNodes = this.connections[this.windowObj.selectingNode] || []
      showingNodes.push(this.windowObj.selectingNode)
    } else {
      const displayChunksCount = this.windowObj.displayChunksCount || 0
      selectedLayout = this.layoutsByChunk[displayChunksCount]
      showingNodes = Object.keys(selectedLayout)
    }

    return { selectedLayout, showingNodes }
  }

  get #mouseX() { return this.cbObj.x || this.windowObj.lastMouseX || 0 }
  get #mouseY() { return this.cbObj.y || this.windowObj.lastMouseY || 0 }
  get #shiftX() { return this.windowObj.previousShiftX || 0 }
  get #shiftY() { return this.windowObj.previousShiftY || 0 }
  get #nodesIndex() { return this.nodeSource.data["index"] }
  get #sourceNodes() { return this.edgeSource.data["start"] }
  get #targetNodes() { return this.edgeSource.data["end"] }
}

const graphManager = new GraphManager({
  graphRenderer,
  connectionsData,
  layoutsByChunkData,
  windowObj: window,
  cbObj: cb_obj,
})
