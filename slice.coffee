# slices nasa .img files into .png "zones" readable by canvas

# map.json:
#   deltaY = difference between max and min elevation in map
#   29457m:  highest point: olympus mons at 21249m, lowest: hellas planitia at -8208m
#   heightScale: by default it's calculated by deltaY / metersPerPixel

fse = require 'fs-extra'
{PNG} = require 'pngjs'
Buffer = require('buffer').Buffer

map = require './maps/mars/map.coffee'

global.log = console.log

time =
  start: process.hrtime()

inputMapPath = "./maps/#{map.name}"
outputMapPath = "./public/maps/#{map.name}"

log "using map info #{JSON.stringify map}"

zoneDir = "#{outputMapPath}/zones"

log 'deleting current zone dir at ', zoneDir
fse.removeSync zoneDir

map.heightmap ?= 'megt90n000fb.img'
map.cols ?= 1
map.rows ?= 1
map.fullwidth = map.width * map.cols
map.fullheight = map.height * map.rows

{zones} = map.renderOptions
zones ?= {}
zones.cols ?= 1
zones.rows ?= 1
zones.width = Math.round(map.width / zones.cols)
zones.height = Math.round(map.height / zones.rows)

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
    heightMapPath = "#{inputMapPath}/#{map.heightmap}"
  else
    heightMapPath = "#{inputMapPath}/heightmap/x#{col}y#{row}.img"

  log "loading height map from #{heightMapPath}"

  fd = fse.openSync heightMapPath, 'r'
  totalSize = (map.width * bytesPerPixel) * (map.height * bytesPerPixel)
  buffer = new Buffer totalSize
  fse.readSync fd, buffer, 0, totalSize, 0
  
  createZone = (zx, zy) ->
    log 'creating zone png for X', zx, ', Y', zy

    zone = new PNG width: zones.width, height: zones.height

    start =
      x: ((zx - (col * zones.cols)) * zones.width)
      y: ((zy - (row * zones.rows)) * zones.height)

    log start

    for y in [(start.y)...(start.y + zones.height)]
      for x in [(start.x)...(start.x + zones.width)]
        bufPosition = ((map.width * bytesPerPixel) * y) + (x * bytesPerPixel)
        original = buffer.readInt16BE(bufPosition)
        # making it unsigned
        unsigned = original + maxNegativeInt16
        # using min-max scale
        scaled = (unsigned - min.value) / (max.value - min.value)
        # scaling down to 0 - 255
        hex = Math.round(scaled * maxColor)
        
        # << = left shift operator
        idx = (zone.width * (y - start.y) + (x - start.x)) << 2
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
      if zx >= (zones.cols * (col + 1))
        zx = col * zones.cols
        zy++
        log 'next y'
      if zy < (zones.rows * (row + 1))
        createZone zx, zy
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
          time.diff = process.hrtime(time.start)
          console.log time
          log 'THE END'

    zone.pack().pipe wStream

  createZone col * zones.cols, row * zones.rows

readFile row, col

