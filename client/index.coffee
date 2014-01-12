window.log = -> console.log.apply console, arguments

vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'
vsky = require 'voxel-sky'

mapData = require '../maps/mars/map.coffee'
{getHeightFromColor} = require './common.coffee'

Map = require './map.coffee'
map = new Map mapData

skyDescription = require('./sky.coffee') map.skyHue

LoadProgress = require './load-progress.coffee'
Chunk = require './chunk.coffee'

NavMap = require './nav-map.coffee'

window.app = {map}

getHashParams = ->
  params = {}
  for param in window.location.hash.substring(1).split('&')
    if param
      parts = param.split '='
      params[parts[0]] = parts.splice(1).join '='

  window.location.hash = ''

  params

$ ->
  worldDiv = $('#world')
  welcome = $('#welcome')
  progress = $('#welcome progress')
  playButton = $('#play')

  navMap = new NavMap map

  positionElem = $('#position')
  lat = $('#lat')
  lng = $('#lng')
  alt = $('#alt')

  permalink = $('#permalink')
  help = $('#help')

  map.setStartPoint getHashParams()

  origin = map.getOrigin()

  game = app.game = vengine
    materials: [map.name]
    generateChunks: no
    chunkSize: map.chunkSize
    chunkDistance: map.chunkDistance
    worldOrigin: origin
    controls: {discreteFire: true}
    lightsDisabled: yes

  game.appendTo worldDiv[0]

  if game.notCapable()
    welcome.hide()
    navMap.container.hide()
    positionElem.hide()
    return

  createSky = vsky
    game: game
    size: (game.worldWidth() * 3) * 0.8
    time: 1200

  sky = createSky skyDescription

  lp = new LoadProgress
    chunkDistance: map.chunkDistance
    mapImg: navMap.img
    onUpdate: (prog) ->
      progress.attr prog
    onComplete: (prog) ->
      playButton.text 'land!'
      playButton.removeAttr 'disabled'
      game.paused = yes

  target = null
  avatar = null

  startGame = ->
    avatar = vplayer(game)('astronaut.png')
    avatar.possess()
    avatar.position.set(map.startPoint.x + 0.5, map.startPoint.y + map.playerOffset, map.startPoint.z + 0.5)

    target = game.controls.target()

    game.paused = no

  spawnInfo = 
    map: map
    coords: origin
    game: game
    lp: lp
    onRender: ->
      offset = 
        x: map.startPoint.x - (origin[0] * map.chunkSize)
        z: map.startPoint.z - (origin[2] * map.chunkSize)
      data = @zone.ctx.getImageData(@relativePosition.x + offset.x, @relativePosition.z + offset.z, 1, 1).data

      # only consider first channel, red
      map.startPoint.y = getHeightFromColor data[0], map.heightScale, map.heightOffset

      chunkY = Math.floor(map.startPoint.y / map.chunkSize)

      if chunkY == 0
        startGame()
      else
        origin[1] = chunkY
        spawnInfo.onRender = startGame
        spawnChunk = new Chunk spawnInfo

  spawnChunk = new Chunk spawnInfo

  position = null

  game.on 'tick', (dt) ->
    time = sky(dt).time
    vwalk.render(target.playerSkin)
    vx = Math.abs(target.velocity.x)
    vz = Math.abs(target.velocity.z)
    if vx > 0.001 or vz > 0.001 then vwalk.stopWalking()
    else vwalk.startWalking()

  updateLatLngAlt = (pos) ->
    pos = map.toLatLngAlt pos
    lat.text pos.lat.toFixed 7
    lng.text pos.lng.toFixed 7
    alt.text pos.alt.toFixed 2
    permalink.attr 'href', "#lat=#{pos.lat}&lng=#{pos.lng}"
    positionElem.show()

  game.voxelRegion.on 'change', (pos) ->
    position = map.toPositionPoint pos
    navMap.update position
    updateLatLngAlt position

  togglePause = ->
    if lp.complete
      game.paused = !game.paused
      welcome.toggle()
      progress.hide()
      playButton.text 'resume'

  $(window).keydown (ev) ->
    onWelcome = welcome.css('display') isnt 'none'

    if !onWelcome and ev.keyCode is 'C'.charCodeAt(0)
      avatar.toggle()

    else if !onWelcome and ev.keyCode is 'M'.charCodeAt(0)
      navMap.toggle position or target.position

    else if ev.keyCode is 'P'.charCodeAt(0)
      togglePause()

  playButton.click (e) ->
    e.preventDefault()
    togglePause()

  help.click (e) ->
    e.preventDefault()
    togglePause()

  game.voxels.on 'missingChunk', (coords) ->
    new Chunk {map, coords, game, lp}

