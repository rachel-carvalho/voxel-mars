# Converts the 128px/deg MOLA MEGDR provided by NASA into .PNG "zones" used by voxel-mars

log = console.log
fse = require 'fs-extra'
{PNG} = require 'pngjs'
Buffer = require('buffer').Buffer

map = require './world.coffee'
log "using map info #{JSON.stringify map}"

time = start: process.hrtime()

inputMapPath = "./src/height"
zoneDir = outputMapPath = "./out/height"

log 'deleting current zone dir at ', zoneDir
fse.removeSync zoneDir

# a "tile" is each .IMG file provided by NASA

tileCols = 4
tileRows = 4

tileWidth = map.width / tileCols
tileHeight = map.width / tileRows

# a "zone" is each .PNG file used by voxel-mars

zoneCols = map.cols
zoneRows = map.rows

zoneColsPerTile = zoneCols / tileCols
zoneRowsPerTile = zoneRows / tileRows

zoneWidth = Math.round(map.width / zoneCols)
zoneHeight = Math.round(map.height / zoneRows)

log "reading heightmap from #{tileRows} rows and #{tileCols} cols"

row = 0
col = 0

bytesPerPixel = 2
maxNegativeInt16 = 32768
maxColor = 255

min = {value: 24560, points: [{x: 7961, y: 4212}]}
max = {value: 54017, points: [{x: 5958, y: 3412}]}

readFile = (row, col) ->
  heightMapPath = "#{inputMapPath}/x#{col}y#{row}.img"

  log "loading height map from #{heightMapPath}"

  fd = fse.openSync heightMapPath, 'r'
  totalSize = (tileWidth * bytesPerPixel) * (tileHeight * bytesPerPixel)
  buffer = new Buffer totalSize
  fse.readSync fd, buffer, 0, totalSize, 0
  
  createZone = (zx, zy) ->
    log 'creating zone png for X', zx, ', Y', zy

    zone = new PNG width: zoneWidth, height: zoneHeight

    start =
      x: ((zx - (col * zoneColsPerTile)) * zoneWidth)
      y: ((zy - (row * zoneRowsPerTile)) * zoneHeight)

    log start

    for y in [(start.y)...(start.y + zoneHeight)]
      for x in [(start.x)...(start.x + zoneWidth)]
        bufPosition = ((tileWidth * bytesPerPixel) * y) + (x * bytesPerPixel)
        original = buffer.readInt16BE(bufPosition)
        # making it unsigned
        unsigned = original + maxNegativeInt16
        # using min-max scale
        scaled = (unsigned - min.value) / (max.value - min.value)
        # scaling down to 0 - 255
        hex = Math.round(scaled * maxColor)
        
        # << = left shift operator
        idx = (zoneWidth * (y - start.y) + (x - start.x)) << 2
        # red channel only
        zone.data[idx] = hex
        # alpha ff
        zone.data[idx + 3] = 0xff

    pngDir = "#{zoneDir}/x#{zx}"
    pngPath = "#{pngDir}/y#{zy}.png"

    fse.mkdirsSync pngDir
    
    log 'writing png at ', pngPath

    wStream = fse.createWriteStream pngPath

    wStream.on 'finish', ->
      zx++
      log 'next x'
      if zx >= (zoneColsPerTile * (col + 1))
        zx = col * zoneColsPerTile
        zy++
        log 'next y'
      if zy < (zoneRowsPerTile * (row + 1))
        createZone zx, zy
      else
        log 'next file x'
        col++
        if col >= tileCols
          col = 0
          row++
          log 'next file y'
        if row < tileRows
          readFile row, col
        else
          time.diff = process.hrtime(time.start)
          console.log time
          log 'THE END'

    zone.pack().pipe wStream

  createZone col * zoneColsPerTile, row * zoneRowsPerTile

readFile row, col

