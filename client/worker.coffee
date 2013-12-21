{getHeightFromColor} = require './common.coffee'

self.addEventListener 'message', (e) ->
  switch e.data.cmd
    when 'generateChunk'
      info = e.data.chunkInfo
      
      info.heightMap = new Uint8ClampedArray info.heightMap

      msg = 
        event: 'chunkGenerated'
        chunk: 
          voxels: generateChunk(info).buffer
          position: info.positionRaw

      
      self.postMessage msg, [msg.chunk.voxels]

log = (msg) ->
  self.postMessage
    event: 'log'
    msg: msg

getChunkIndex = (x, y, z, size) ->
  xIndex = Math.abs((size + x % size) % size)
  yIndex = Math.abs((size + y % size) % size)
  zIndex = Math.abs((size + z % size) % size)

  xIndex + (yIndex * size) + (zIndex * size * size)

generateChunk = (info) ->
  {heightMap, position, size, heightScale, heightOffset} = info
  chunk = new Int8Array(size * size * size)

  if position.y > -1
    startY = position.y * size

    for z in [0...size]
      for x in [0...size]
        imgIdx = (size * z + x) << 2
        data = heightMap[imgIdx]
        height = getHeightFromColor data, heightScale, heightOffset
        endY = startY + size

        if endY > height >= startY
          chunk[getChunkIndex(x, height, z, size)] = 1

          secondLayer = height - 1
          if secondLayer >= startY
            chunk[getChunkIndex(x, secondLayer, z, size)] = 1
  chunk
