window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'
map = require '../public/maps/mars/map.json'
{getHeightFromColor} = require './common.coffee'

window.app = {}

worker = app.worker = new Worker '/js/worker.js'

mapDir = 'maps/mars'

$ ->
  getHashParams = ->
    params = {}
    for param in window.location.hash.substring(1).split('&')
      if param
        parts = param.split '='
        params[parts[0]] = parts.splice(1).join '='
    params

  hashParams = getHashParams()

  app.map = map
  map.heightScale ?= map.deltaY / map.metersPerPixel
  map.metersPerVoxelVertical = map.deltaY / map.heightScale
  # all heights are added one to avoid holes at altitude 0
  map.heightOffset = 1
  # player is one voxel on top of the floor
  map.playerOffset = 1
  # TODO: calculate center from chosen POI
  map.cols ?= 1
  map.rows ?= 1
  map.fullwidth = map.width * map.cols
  map.fullheight = map.height * map.rows
  map.center = {x: map.fullwidth / 2, y: map.fullheight / 2}
  map.latLngCenterInPx =
    lat: map.center.y
    lng: 0

  if map.generateOptions.startPosition
    poi = map.pointsOfInterest[map.generateOptions.startPosition]
    if poi
      map.center.x = ((poi.nasaFile?.x || 0) * map.width) + poi.x
      map.center.y = ((poi.nasaFile?.y || 0) * map.height) + poi.y

  fromLatLng = (latLng) ->
    {lat, lng} = latLng
    lat = parseFloat lat
    lng = parseFloat lng
    lng += 360 if lng < 0

    pos =
      x: lng * map.pixelsPerDegree
      y: -(lat * map.pixelsPerDegree) + map.latLngCenterInPx.lat

    pos

  if hashParams.lat and hashParams.lng
    map.center = fromLatLng hashParams
    window.location.hash = ''
    hashParams = {}

  {chunkSize, zones} = map.generateOptions
  zones ?= {}
  zones.cols ?= 1
  zones.rows ?= 1
  zones.width = Math.round(map.width / zones.cols)
  zones.height = Math.round(map.height / zones.rows)

  origin = [Math.floor(map.center.x / chunkSize), 0, Math.floor(map.center.y / chunkSize)]

  game = app.game = vengine
    materials: ['mars']
    materialFlatColor: no
    generateChunks: no
    chunkSize: chunkSize
    chunkDistance: 3
    worldOrigin: origin
    controls: {discreteFire: true}
    skyColor: 0xFA8072
    playerHeight: 3

  game.appendTo $('#world')[0]

  convertChunkToZone = (chunkPosition) ->
    pixelPos = 
      x: chunkPosition.x * chunkSize
      z: chunkPosition.z * chunkSize
    
    zone =
      x: Math.floor(pixelPos.x / zones.width)
      z: Math.floor(pixelPos.z / zones.height)

    relativePosition =
      x: pixelPos.x % zones.width
      z: pixelPos.z % zones.height

    {zone, relativePosition}

  renderChunk = (ctx, imgPosition, chunkPosition, chunkPositionRaw) ->
    data = ctx.getImageData(imgPosition.x, imgPosition.z, chunkSize, chunkSize).data
    chunkInfo =
      heightMap: data
      position: chunkPosition
      positionRaw: chunkPositionRaw
      size: chunkSize
      heightScale: map.heightScale
      heightOffset: map.heightOffset

    worker.postMessage 
      cmd: 'generateChunk'
      chunkInfo: chunkInfo
      ,
      [data.buffer]

  loadedZones = {}

  onChunkRendered = {}

  loadChunk = (chunkPositionRaw, cb) ->
    chunkPosition = x: chunkPositionRaw[0], y: chunkPositionRaw[1], z: chunkPositionRaw[2]

    {zone, relativePosition} = convertChunkToZone chunkPosition

    zone.key = "x#{zone.x}/y#{zone.z}"

    if loadedZones[zone.key]
      if loadedZones[zone.key].loading
        loadedZones[zone.key].toRender.push {relativePosition, chunkPosition, chunkPositionRaw, cb}
      else
        renderChunk loadedZones[zone.key].ctx, relativePosition, chunkPosition, chunkPositionRaw
    else
      loadedZones[zone.key] =
        x: zone.x
        z: zone.z
        loading: yes
        toRender: [{relativePosition, chunkPosition, chunkPositionRaw, cb}]

      hmImg = new Image()
      hmImg.onload = ->
        loadedZones[zone.key].canvas = canvas = document.createElement 'canvas'
        canvas.width = zones.width
        canvas.height = zones.height
        loadedZones[zone.key].ctx = ctx = canvas.getContext '2d'
        ctx.drawImage this, 0, 0
        loadedZones[zone.key].loading = no
        
        for chunk in loadedZones[zone.key].toRender
          {relativePosition, chunkPosition, chunkPositionRaw} = chunk
          if typeof chunk.cb == 'function'
            onChunkRendered["x#{chunkPosition.x}y#{chunkPosition.y}z#{chunkPosition.z}"] = 
              cb: chunk.cb
              ctx: ctx
              relativePosition: relativePosition
          renderChunk ctx, relativePosition, chunkPosition, chunkPositionRaw
        loadedZones[zone.key].toRender = []
        
      hmImg.src = "#{mapDir}/zones/#{zone.key}.png"

  target = null

  loadChunk origin, (ctx, imgPosition) ->
    offset = 
      x: map.center.x - (origin[0] * chunkSize)
      y: map.center.y - (origin[2] * chunkSize)
    data = ctx.getImageData(imgPosition.x + offset.x, imgPosition.z + offset.y, 1, 1).data
    y = 0
    # only consider first channel, red
    for color in data by 4
      y = Math.max y, getHeightFromColor(color, map.heightScale, map.heightOffset)

    avatar = vplayer(game)('astronaut.png')
    avatar.possess()
    avatar.position.set(map.center.x + 0.5, y + map.playerOffset, map.center.y + 0.5)
    avatar.toggle()

    target = game.controls.target()

    game.paused = no

  position = null

  game.on 'tick', ->
    vwalk.render(target.playerSkin)
    vx = Math.abs(target.velocity.x)
    vz = Math.abs(target.velocity.z)
    if vx > 0.001 or vz > 0.001 then vwalk.stopWalking()
    else vwalk.startWalking()

  div = $('#mid-map')
  pointer = $('#pointer')
  img = $('#mid-map img')
  positionDiv = $('#position')
  lat = $('#lat')
  lng = $('#lng')
  alt = $('#alt')
  permalink = $('#permalink')

  updateMidmap = (pos) ->
    pointer.css
      top: (pos.z / map.fullheight) * img.height()
      left: (pos.x / map.fullwidth) * img.width()

  toLatLngAlt = (pos) ->
    latLngAlt =
      lat: -((pos.z - map.latLngCenterInPx.lat) / map.pixelsPerDegree)
      lng: pos.x / map.pixelsPerDegree
      alt: ((pos.y - map.heightOffset - map.playerOffset) * map.metersPerVoxelVertical) - map.datum
    latLngAlt.lng -= 360 if latLngAlt.lng > 180

    latLngAlt

  updateLatLngAlt = (pos) ->
    pos = toLatLngAlt pos
    lat.text pos.lat.toFixed 7
    lng.text pos.lng.toFixed 7
    alt.text pos.alt.toFixed 2
    permalink.attr 'href', "#lat=#{pos.lat}&lng=#{pos.lng}"
    positionDiv.show()

  game.voxelRegion.on 'change', (pos) ->
    position = x: pos[0], y: pos[1], z: pos[2]
    updateMidmap position
    updateLatLngAlt position

  $(window).keydown (ev) ->
    if ev.keyCode is 'M'.charCodeAt(0)
      div.toggle()

      updateMidmap position ? target.position

  game.voxels.on 'missingChunk', loadChunk

  worker.addEventListener 'message', (e) ->
    switch e.data.event
      when 'log'
        log e.data.msg
      when 'chunkGenerated'
        key = "x#{e.data.chunk.position[0]}y#{e.data.chunk.position[1]}z#{e.data.chunk.position[2]}"

        game.showChunk
          position: e.data.chunk.position
          dims: [chunkSize, chunkSize, chunkSize]
          voxels: e.data.chunk.voxels

        if onChunkRendered[key]
          onChunkRendered[key].cb onChunkRendered[key].ctx, onChunkRendered[key].relativePosition
          onChunkRendered[key] = null

