window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'
mapData = require '../maps/mars/map.coffee'
{getHeightFromColor} = require './common.coffee'
WorkCrew = require '../public/js/workcrew.js'

Map = require './map.coffee'
map = new Map mapData

window.app = {map}

crew = app.crew = new WorkCrew '/js/worker.js', 2

mapDir = "maps/#{map.name}"

getHashParams = ->
  params = {}
  for param in window.location.hash.substring(1).split('&')
    if param
      parts = param.split '='
      params[parts[0]] = parts.splice(1).join '='
  params

$ ->

  hashParams = getHashParams()

  if hashParams.lat and hashParams.lng
    map.startPoint = map.fromLatLng hashParams
    window.location.hash = ''
    hashParams = {}

  origin = map.getOrigin()

  game = app.game = vengine
    materials: [map.name]
    materialFlatColor: no
    generateChunks: no
    chunkSize: map.chunkSize
    chunkDistance: map.chunkDistance
    worldOrigin: origin
    controls: {discreteFire: true}
    skyColor: map.skyColor

  game.appendTo $('#world')[0]

  welcome = $('#welcome')
  progress = $('#welcome progress')
  playButton = $('#play')
  div = $('#map')
  img = $('#map img')
  vertical = $('#vertical')
  horizontal = $('#horizontal')
  positionElem = $('#position')
  lat = $('#lat')
  lng = $('#lng')
  alt = $('#alt')
  permalink = $('#permalink')
  help = $('#help')

  if game.notCapable()
    welcome.hide()
    div.hide()
    positionElem.hide()
    return

  chunkProgress =
    value: 0
    max: Math.pow map.chunkDistance * 2, 3

  imgProgress = 
    max: Math.floor chunkProgress.max / 4
  
  chunkProgress.max += imgProgress.max

  playButton.click (e) ->
    e.preventDefault()
    togglePause()

  updateProgress = (val = 1) ->
    return unless playButton.is ':disabled'
    chunkProgress.value += val
    prog = chunkProgress
    progress.attr prog
    if prog.value is prog.max
      playButton.text 'land!'
      playButton.removeAttr 'disabled'
      game.paused = yes

  img.bind 'load', ->
    updateProgress imgProgress.max

  updateProgress 0

  onChunkRendered = {}

  renderChunk = (ctx, relativePosition, chunkPosition, chunkPositionRaw, cb) ->
    if typeof cb == 'function'
      key = "x#{chunkPosition.x}y#{chunkPosition.y}z#{chunkPosition.z}"
      onChunkRendered[key] = {cb, ctx, relativePosition}

    data = ctx.getImageData(relativePosition.x, relativePosition.z, map.chunkSize, map.chunkSize).data

    chunkInfo =
      heightMap: data.buffer
      position: chunkPosition
      positionRaw: chunkPositionRaw
      size: map.chunkSize
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
    chunkPosition = map.toPositionChunk chunkPositionRaw

    {zone, relativePosition} = map.convertChunkToZone chunkPosition

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
        canvas.width = map.zones.width
        canvas.height = map.zones.height
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
    avatar.position.set(map.startPoint.x + 0.5, map.startPoint.y + map.playerOffset, map.startPoint.z + 0.5)

    target = game.controls.target()

    game.paused = no

  loadChunk origin, (ctx, imgPosition) ->
    offset = 
      x: map.startPoint.x - (origin[0] * map.chunkSize)
      z: map.startPoint.z - (origin[2] * map.chunkSize)
    data = ctx.getImageData(imgPosition.x + offset.x, imgPosition.z + offset.z, 1, 1).data

    # only consider first channel, red
    map.startPoint.y = getHeightFromColor data[0], map.heightScale, map.heightOffset

    chunkY = Math.floor(map.startPoint.y / map.chunkSize)

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

  help.click (e) ->
    e.preventDefault()
    togglePause()

  updateMap = (pos, mini) ->
    height = img.height()
    width = img.width()

    {top, left} = map.toTopLeft pos, width, height

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

  updateLatLngAlt = (pos) ->
    pos = map.toLatLngAlt pos
    lat.text pos.lat.toFixed 7
    lng.text pos.lng.toFixed 7
    alt.text pos.alt.toFixed 2
    permalink.attr 'href', "#lat=#{pos.lat}&lng=#{pos.lng}"
    positionElem.show()

  game.voxelRegion.on 'change', (pos) ->
    position = map.toPositionPoint pos
    updateMap position, div.hasClass 'mini'
    updateLatLngAlt position

  toggleMap = ->
    div.toggleClass('mini').toggleClass('global')
    updateMap position ? target.position, div.hasClass 'mini'

  togglePause = ->
    return if playButton.is ':disabled'

    game.paused = !game.paused
    welcome.toggle()
    progress.hide()
    playButton.text 'resume'

  $(window).keydown (ev) ->
    onWelcome = welcome.css('display') isnt 'none'

    if !onWelcome and ev.keyCode is 'C'.charCodeAt(0)
      avatar.toggle()

    else if !onWelcome and ev.keyCode is 'M'.charCodeAt(0)
      toggleMap()

    else if ev.keyCode is 'P'.charCodeAt(0)
      togglePause()

  div.click (e) ->
    return unless div.hasClass 'global'

    pos = map.fromTopLeft {top: e.pageY, left: e.pageX}, img.width(), img.height()

    latLng = map.toLatLngAlt pos

    location.hash = "#lat=#{latLng.lat}&lng=#{latLng.lng}"
    location.reload()

  game.voxels.on 'missingChunk', loadChunk

  crew.oncomplete = (r) ->
    e = r.result
    switch e.data.event
      when 'log'
        log e.data.msg
      when 'chunkGenerated'
        pos = map.toPositionChunk e.data.chunk.position
        key = "x#{pos.x}y#{pos.y}z#{pos.z}"

        chunk =
          position: e.data.chunk.position
          dims: [map.chunkSize, map.chunkSize, map.chunkSize]
          voxels: new Int8Array e.data.chunk.voxels

        game.showChunk chunk

        updateProgress()

        if onChunkRendered[key]
          onChunkRendered[key].cb onChunkRendered[key].ctx, onChunkRendered[key].relativePosition
          onChunkRendered[key] = null

