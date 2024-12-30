(function() {
  if (window.displayChunksCount === undefined) { window.displayChunksCount = 0 }
  const displayChunksCount = window.displayChunksCount
  if (window.previousShiftX === undefined) { window.previousShiftX = 0 }
  if (window.previousShiftY === undefined) { window.previousShiftY = 0 }

  const mouseX = cb_obj.x
  const mouseY = cb_obj.y
  const selectedLayout = JSON.parse(layoutsByChunk)[displayChunksCount]
  const connections = JSON.parse(connectionsData)
  const nodesIndex = nodeSource.data["index"]

  let closestNodeName
  let minmumDistance = Infinity
  nodesIndex.forEach((nodeName, i) => {
    if (selectedLayout[nodeName] === undefined) { return }
    const dx = selectedLayout[nodeName][0] - mouseX + window.previousShiftX
    const dy = selectedLayout[nodeName][1] - mouseY + window.previousShiftY
    const distance = dx * dx + dy * dy
    if (distance < minmumDistance) {
      minmumDistance = distance
      closestNodeName = nodesIndex[i]
    }
  })

  if (closestNodeName && minmumDistance < 0.005) {
    const connectedNodes = connections[closestNodeName] || []
    nodeSource.data['radius'] = nodesIndex.map(nodeName => {
      if (nodeName === closestNodeName) {
        return EMPTHASIS_SIZE
      } else {
        return BASIC_SIZE
      }
    })
    nodeSource.data['fill_color'] = nodesIndex.map(nodeName => {
      if (nodeName === closestNodeName || selectedLayout[nodeName] && connectedNodes.includes(nodeName)) {
        return HIGHLIGHT_COLOR
      } else {
        return BASIC_COLOR
      }
    })
  } else {
    nodeSource.data['radius'] = nodesIndex.map(() => BASIC_SIZE)
    nodeSource.data['fill_color'] = nodesIndex.map(() => BASIC_COLOR)
  }

  nodeSource.change.emit()
})()
