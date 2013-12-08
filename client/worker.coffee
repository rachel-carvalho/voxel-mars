self.addEventListener 'message', (e) ->
  switch e.data.cmd
    when 'generateChunk'
      info = e.data.chunkInfo
      self.postMessage
        event: 'chunkGenerated'
        chunk: 
          voxels: generateChunk info
          position: info.positionRaw

generateChunk = (info) ->
  {heightMap, position, size, heightScale} = info
  chunk = new Int8Array(size * size * size)

  if position.y is 0
    for x in [0...size]
      for z in [0...size]
        height = Math.ceil (heightMap[Math.abs z][Math.abs x] / 255) * heightScale

        for y in [0..height]
          xIndex = Math.abs((size + x % size) % size)
          yIndex = Math.abs((size + y % size) % size)
          zIndex = Math.abs((size + z % size) % size)
      
          index = xIndex + (yIndex * size) + (zIndex * size * size)
          chunk[index] = 1

  chunk