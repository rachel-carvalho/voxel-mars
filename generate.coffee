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
  center = { x: Math.floor(map.width / 2), y: Math.floor(map.height / 2) }

  xChunks = calculateChunk map.width, map.generateOptions.chunkSize
  yChunks = calculateChunk map.height, map.generateOptions.chunkSize

  log 'preparing to generate chunks, x: ', xChunks, ', y: ', yChunks
  for cy in [yChunks.start..yChunks.end]
    for cx in [xChunks.start..xChunks.end]
      log 'extracting chunk data for X', cx, ', Y', cy

      start =
        x: center.x + (cx * map.generateOptions.chunkSize)
        y: center.y + (cy * map.generateOptions.chunkSize)
        
      chunk = []

      for y in [(start.y)...(start.y + map.generateOptions.chunkSize)]
        chunk[y - start.y] = []
        for x in [(start.x)...(start.x + map.generateOptions.chunkSize)]
          # << = left shift operator
          idx = (map.width * y + x) << 2
          chunk[y - start.y][x - start.x] = @data[idx]

      chunkJSONPath = "#{chunkDir}/x#{cx}/y#{cy}.json"
      
      log 'writing json at ', chunkJSONPath
      
      fse.outputFileSync chunkJSONPath, JSON.stringify(chunk)
