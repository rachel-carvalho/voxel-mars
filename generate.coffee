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

log "using map info #{JSON.stringify map}"

calculateChunk = (voxels, chunkSize) ->
  qty = Math.ceil voxels / chunkSize
  {
    start: -(Math.ceil((qty - 1) / 2))
    end: Math.floor((qty - 1) / 2)
  }

chunkDir = "#{mapPath}/chunks"

log 'deleting current chunk dir at ', chunkDir
fse.removeSync chunkDir

map.heightmap ?= 'heightmap.png'
map.cols ?= 1
map.rows ?= 1
map.fullwidth = map.width * map.cols
map.fullheight = map.height * map.rows

center =
  x: Math.floor(map.fullwidth / 2)
  y: Math.floor(map.fullheight / 2)

log {center}

{chunkSize} = map.generateOptions

xChunks = calculateChunk map.fullwidth, chunkSize
yChunks = calculateChunk map.fullheight, chunkSize

log {yChunks, xChunks}

chunkArray =
  y: [yChunks.start..yChunks.end]
  x: [xChunks.start..xChunks.end]

chunksPerFile =
  y: Math.ceil(chunkArray.y.length / map.rows)
  x: Math.ceil(chunkArray.x.length / map.cols)

log {chunksPerFile}

log "reading heightmap from #{map.rows} rows and #{map.cols} cols"

row = 0
col = 0

readFile = (row, col) ->
  if map.cols == 1 and map.rows == 1
    heightMapPath = "#{mapPath}/#{map.heightmap}"
  else
    heightMapPath = "#{mapPath}/heightmap/x#{col}y#{row}.png"

  log "loading height map from #{heightMapPath}"

  fse.createReadStream(heightMapPath).pipe(new PNG filterType: 4).on 'parsed', ->
    rawData = @data

    chunks = []

    section =
      y:
        start: row * chunksPerFile.y
      x:
        start: col * chunksPerFile.x

    section.y.end = section.y.start + chunksPerFile.y
    section.x.end = section.x.start + chunksPerFile.x

    for cy in chunkArray.y[section.y.start...section.y.end]
      for cx in chunkArray.x[section.x.start...section.x.end]
        log 'creating chunk png for X', cx, ', Y', cy

        chunk = new PNG width: chunkSize, height: chunkSize

        start =
          x: center.x + (cx * chunkSize) - (col * map.width)
          y: center.y + (cy * chunkSize) - (row * map.height)

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
        else
          col++
          if col < map.cols
            readFile row, col
          else
            row++
            col = 0
            if row < map.rows
              readFile row, col
            else
              log 'THE END'

      chunks[chunkIdx].chunk.pack().pipe wStream

    writeChunk()

readFile row, col

