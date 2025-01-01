// return { closestNodeName[String, undefined], minmumDistance[Float] }
function findClosestNodeWithMinmumDistance(mousePosition, nodesIndex, layout, window) {
  const mouseX = mousePosition.x
  const mouseY = mousePosition.y
  const shiftX = window.previousShiftX || 0
  const shiftY = window.previousShiftY || 0

  let closestNodeName
  let minmumDistance = Infinity

  nodesIndex.forEach((nodeName, i) => {
    if (layout[nodeName] === undefined) { return }
    const dx = layout[nodeName][0] + shiftX - mouseX
    const dy = layout[nodeName][1] + shiftY - mouseY
    const distance = dx * dx + dy * dy
    if (distance < minmumDistance) {
      minmumDistance = distance
      closestNodeName = nodesIndex[i]
    }
  })
  return { closestNodeName: closestNodeName, minmumDistance: minmumDistance }
}

// return [nodesX[Array], nodexY[Array]]
function updateNodeXY(nodeSource, nodesIndex, layout) {
  const nodesX = nodeSource.data["x"]
  const nodesY = nodeSource.data["y"]
  nodesIndex.forEach((nodeName, i) => {
    if (layout[nodeName]) {
      const [newX, newY] = layout[nodeName]
      nodesX[i] = newX
      nodesY[i] = newY
    }
  })
  return [nodesX, nodesY]
}
