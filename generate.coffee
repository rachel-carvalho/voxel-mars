# generates map terrain as x_y.json files

# map.json:
#   deltaY = difference between max and min elevation in map
#   29429m:  highest point: olympus mons at 21229m, lowest: hellas planitia at -8200m
#   "heightmap": "heightmap.png",
#   "midmap": "midmap.jpg",
#   heightScale: by default it's calculated by deltaY / metersPerPixel


jbinary = require 'jbinary'
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

map.heightmap ?= 'megt90n000fb.img'
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

bytesPerPixel = 2
maxNegativeInt16 = 32768
maxColor = 255

min = {"value":24560,"points":[{"x":7961,"y":4212}]}
max = {"value":54017,"points":[{"x":5958,"y":3412}]}

readFile = (row, col) ->
  if map.cols == 1 and map.rows == 1
    heightMapPath = "#{mapPath}/#{map.heightmap}"
  else
    # heightMapPath = "#{mapPath}/heightmap/x#{col}y#{row}.png"
    throw 'multi-file not implemented yet'

  log "loading height map from #{heightMapPath}"

  typeSet =
    img:
      'jBinary.littleEndian': false
      pixel: 'int16'

  jbinary.load heightMapPath, typeSet, (err, binary) ->
    chunks = []

    section =
      y:
        start: row * chunksPerFile.y
      x:
        start: col * chunksPerFile.x

    section.y.end = section.y.start + chunksPerFile.y
    section.x.end = section.x.start + chunksPerFile.x

    createChunk = (cx, cy) ->
      log 'creating chunk png for X', cx, ', Y', cy

      chunk = new PNG width: chunkSize, height: chunkSize

      start =
        x: center.x + (cx * chunkSize) - (col * map.width)
        y: center.y + (cy * chunkSize) - (row * map.height)

      for y in [(start.y)...(start.y + chunkSize)]
        for x in [(start.x)...(start.x + chunkSize)]
          binary.seek ((map.width * bytesPerPixel) * y) + (x * bytesPerPixel)
          original = binary.read('img').pixel
          # making it unsigned
          unsigned = original + maxNegativeInt16
          # using min-max scale
          scaled = (unsigned - min.value) / (max.value - min.value)
          # scaling down to 0 - 255
          hex = Math.round(scaled * maxColor)
          
          # << = left shift operator
          idx = (chunk.width * (y - start.y) + (x - start.x)) << 2
          # same color in all 3 channels
          for offset in [0..2]
            chunk.data[idx + offset] = hex
          # alpha ff for all
          chunk.data[idx + 3] = 0xff

      pngDir = "#{chunkDir}/x#{cx}"
      pngPath = "#{pngDir}/y#{cy}.png"

      fse.mkdirsSync pngDir
      
      log 'writing png at ', pngPath

      wStream = fse.createWriteStream pngPath

      wStream.on 'finish', ->
        cx++
        log 'next x'
        if cx >= chunkArray.x[section.x.end - 1]
          cx = chunkArray.x[section.x.start]
          cy++
          log 'next y'
        if cy < chunkArray.y[section.y.end - 1]
          createChunk cx, cy
        else
          log 'next file x'
          col++
          if col >= map.cols
            col = 0
            row++
            log 'next file y'
          if row < map.rows
            readFile row, col
          else
            log 'THE END'

      chunk.pack().pipe wStream

    createChunk chunkArray.x[section.x.start], chunkArray.y[section.y.start]

readFile row, col

