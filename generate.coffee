# generates map terrain as x_y.json files

# map.json:
#   deltaY = difference between max and min elevation in map
#   29429m:  highest point: olympus mons at 21229m, lowest: hellas planitia at -8200m
#   "heightmap": "heightmap.png",
#   "midmap": "midmap.jpg",
#   heightScale: by default it's calculated by deltaY / metersPerPixel


fse = require 'fs-extra'
{PNG} = require 'pngjs'

global.log = console.log

mapPath = './public/maps/mars'

jsonPath = "#{mapPath}/map.json"

log "loading json at #{jsonPath}"

map = fse.readJsonSync jsonPath
map.heightmap ?= 'heightmap.png'

log "using map info #{JSON.stringify map}"

calculateChunk = (voxels, chunkSize) ->
  qty = Math.ceil voxels / chunkSize
  {
    start: -(Math.ceil (qty - 1) / 2)
    end: Math.floor (qty - 1) / 2
  }

chunkDir = "#{mapPath}/chunks"

log 'deleting current chunk dir at ', chunkDir
fse.removeSync chunkDir

heightMapPath = "#{mapPath}/#{map.heightmap}"

log "loading height map from #{heightMapPath}"

fse.createReadStream(heightMapPath).pipe(new PNG filterType: 4).on 'parsed', ->
  rawData = @data
  center = { x: Math.floor(map.width / 2), y: Math.floor(map.height / 2) }

  {chunkSize} = map.generateOptions

  xChunks = calculateChunk map.width, chunkSize
  yChunks = calculateChunk map.height, chunkSize

  chunks = []

  log 'preparing to generate chunks, x: ', xChunks, ', y: ', yChunks
  for cy in [yChunks.start..yChunks.end]
    for cx in [xChunks.start..xChunks.end]
      log 'creating chunk png for X', cx, ', Y', cy

      chunk = new PNG width: chunkSize, height: chunkSize

      start =
        x: center.x + (cx * chunkSize)
        y: center.y + (cy * chunkSize)
      
      pixelIdx = 0
      for y in [(start.y)...(start.y + chunkSize)]
        for x in [(start.x)...(start.x + chunkSize)]
          # << = left shift operator
          idx = (map.width * y + x) << 2
          chunkIdx = pixelIdx << 2
          for offset in [0..3]
            chunk.data[chunkIdx + offset] = rawData[idx + offset]
          pixelIdx++

      pngDir = "#{chunkDir}/x#{cx}"
      pngPath = "#{pngDir}/y#{cy}.png"

      chunks.push {chunk, pngDir, pngPath}
  
chunkIdx = 0

writeChunk = ->
  fse.mkdirsSync chunks[chunkIdx].pngDir
  
  log 'writing png at ', chunks[chunkIdx].pngPath

  wStream = fse.createWriteStream chunks[chunkIdx].pngPath

  wStream.on 'finish', ->
    chunkIdx++
    if chunkIdx < chunks.length
      writeChunk()

  chunks[chunkIdx].chunk.pack().pipe wStream

writeChunk()