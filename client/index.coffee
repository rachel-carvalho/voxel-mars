window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'
map = require '../public/maps/mars/map.json'
{getHeightFromColor, toPositionObj} = require './common.coffee'
WorkCrew = require '../public/js/workcrew.js'

window.app = {}

crew = app.crew = new WorkCrew '/js/worker.js'

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
  map.center = {x: map.fullwidth / 2, z: map.fullheight / 2}
  map.latLngCenterInPx =
    lat: map.center.z
    lng: 0

  if map.generateOptions.startPosition
    poi = map.pointsOfInterest[map.generateOptions.startPosition]
    if poi
      map.center.x = ((poi.nasaFile?.x || 0) * map.width) + poi.x
      map.center.z = ((poi.nasaFile?.y || 0) * map.height) + poi.y

  fromLatLng = (latLng) ->
    {lat, lng} = latLng
    lat = parseFloat lat
    lng = parseFloat lng
    lng += 360 if lng < 0

    pos =
      x: lng * map.pixelsPerDegree
      z: -(lat * map.pixelsPerDegree) + map.latLngCenterInPx.lat

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

  map.chunks = 
    width: Math.ceil(map.fullwidth / chunkSize)
    height: Math.ceil(map.fullheight / chunkSize)

  origin = [Math.floor(map.center.x / chunkSize), 0, Math.floor(map.center.z / chunkSize)]

  game = app.game = vengine
    materials: ['mars']
    materialFlatColor: no
    generateChunks: no
    chunkSize: chunkSize
    chunkDistance: 3
    worldOrigin: origin
    controls: {discreteFire: true}
    skyColor: 0xf2c8b8

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

  onChunkRendered = {}

  renderChunk = (ctx, relativePosition, chunkPosition, chunkPositionRaw, cb) ->
    if typeof cb == 'function'
      key = "x#{chunkPosition.x}y#{chunkPosition.y}z#{chunkPosition.z}"
      onChunkRendered[key] = {cb, ctx, relativePosition}

    data = ctx.getImageData(relativePosition.x, relativePosition.z, chunkSize, chunkSize).data

    chunkInfo =
      heightMap: data.buffer
      position: chunkPosition
      positionRaw: chunkPositionRaw
      size: chunkSize
      heightScale: map.heightScale
      heightOffset: map.heightOffset

    crew.addWork
      id: chunkPositionRaw.join ','
      msg: 
        cmd: 'generateChunk'
        chunkInfo: chunkInfo
      transferables: [data.buffer]

  loadedZones = {}

  loadChunk = (chunkPositionRaw, cb) ->
    chunkPosition = toPositionObj chunkPositionRaw, map.chunks.width, map.chunks.height

    {zone, relativePosition} = convertChunkToZone chunkPosition

    zone.key = "x#{zone.x}/y#{zone.z}"

    if loadedZones[zone.key]
      if loadedZones[zone.key].loading
        loadedZones[zone.key].toRender.push {relativePosition, chunkPosition, chunkPositionRaw, cb}
      else
        key = "x#{chunkPosition.x}y#{chunkPosition.y}z#{chunkPosition.z}"
        {ctx} = loadedZones[zone.key]
        renderChunk ctx, relativePosition, chunkPosition, chunkPositionRaw, cb
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
          {relativePosition, chunkPosition, chunkPositionRaw, cb} = chunk
          renderChunk ctx, relativePosition, chunkPosition, chunkPositionRaw, cb
        loadedZones[zone.key].toRender = []
        
      hmImg.src = "#{mapDir}/zones/#{zone.key}.png"

  target = null
  avatar = null

  startGame = ->
    avatar = vplayer(game)('astronaut.png')
    avatar.possess()
    avatar.position.set(map.center.x + 0.5, map.center.y + map.playerOffset, map.center.z + 0.5)

    target = game.controls.target()

    game.paused = no

  loadChunk origin, (ctx, imgPosition) ->
    offset = 
      x: map.center.x - (origin[0] * chunkSize)
      z: map.center.z - (origin[2] * chunkSize)
    data = ctx.getImageData(imgPosition.x + offset.x, imgPosition.z + offset.z, 1, 1).data

    # only consider first channel, red
    map.center.y = getHeightFromColor data[0], map.heightScale, map.heightOffset

    chunkY = Math.floor(map.center.y / chunkSize)

    if chunkY == 0
      startGame()
    else
      origin[1] = chunkY
      loadChunk origin, startGame

  position = null

  game.on 'tick', ->
    vwalk.render(target.playerSkin)
    vx = Math.abs(target.velocity.x)
    vz = Math.abs(target.velocity.z)
    if vx > 0.001 or vz > 0.001 then vwalk.stopWalking()
    else vwalk.startWalking()

  div = $('#map')
  vertical = $('#vertical')
  horizontal = $('#horizontal')
  img = $('#map img')
  positionDiv = $('#position')
  lat = $('#lat')
  lng = $('#lng')
  alt = $('#alt')
  permalink = $('#permalink')

  updateMap = (pos, mini) ->
    height = img.height()
    width = img.width()

    top = (pos.z / map.fullheight) * height
    left = (pos.x / map.fullwidth) * width

    if mini
      border = parseInt(div.css('border-left-width'), 10)
      half = (div.width() / 2) - border
      
      img.css
        marginLeft: -left + half
        marginTop: -top + half

      left = top = half

    else
      img.css marginLeft: 0, marginTop:0

    horizontal.css {top, width}
    vertical.css {left, height}

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
    position = toPositionObj pos, map.fullwidth, map.fullheight
    updateMap position, div.hasClass 'mini'
    updateLatLngAlt position

  $(window).keydown (ev) ->
    if ev.keyCode is 'C'.charCodeAt(0)
      avatar.toggle()

    else if ev.keyCode is 'M'.charCodeAt(0)
      div.toggleClass('mini').toggleClass('global')

      updateMap position ? target.position, div.hasClass 'mini'

  game.voxels.on 'missingChunk', loadChunk

  crew.oncomplete = (r) ->
    e = r.result
    switch e.data.event
      when 'log'
        log e.data.msg
      when 'chunkGenerated'
        pos = toPositionObj e.data.chunk.position, map.chunks.width, map.chunks.height
        key = "x#{pos.x}y#{pos.y}z#{pos.z}"

        chunk =
          position: e.data.chunk.position
          dims: [chunkSize, chunkSize, chunkSize]
          voxels: new Int8Array e.data.chunk.voxels

        game.showChunk chunk

        if onChunkRendered[key]
          onChunkRendered[key].cb onChunkRendered[key].ctx, onChunkRendered[key].relativePosition
          onChunkRendered[key] = null

