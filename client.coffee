window.log = -> console.log.apply console, arguments

$ ->
  voxel = require 'voxel'
  vengine = require 'voxel-engine'
  vplayer = require 'voxel-player'
  vwalk = require 'voxel-walk'

  {map} = app

  {chunkSize} = map

  game = app.game = vengine
    materials: ['height5']
    materialFlatColor: no
    generateChunks: no
    chunkSize: chunkSize
    chunkDistance: 2
    worldOrigin: [0, 0, 0]
    controls: {discreteFire: true}
    skyColor: 0xFA8072

  game.appendTo(document.body)

  avatar = vplayer(game)('astronaut.png')
  avatar.possess()
  avatar.position.set(0, 32, 0)
  avatar.toggle()

  target = game.controls.target()

  game.on 'tick', ->
    vwalk.render(target.playerSkin)
    vx = Math.abs(target.velocity.x)
    vz = Math.abs(target.velocity.z)
    if vx > 0.001 or vz > 0.001 then vwalk.stopWalking()
    else vwalk.startWalking()

  div = $('#mid-map')
  pointer = $('#pointer')
  img = $('#mid-map img')

  $(window).keydown (ev) ->
    if ev.keyCode is 'M'.charCodeAt(0)
      pos = target.position

      div.toggle()

      pointer.css top: ((map.center.y + Math.floor pos.z) / map.height) * img.height()
      pointer.css left: ((map.center.x + Math.floor pos.x) / map.width) * img.width()

  game.voxels.on 'missingChunk', (chunkPositionRaw) ->
    chunkPosition = x: chunkPositionRaw[0], y: chunkPositionRaw[1], z: chunkPositionRaw[2]
    $.getJSON "/map/#{chunkPosition.x}/#{chunkPosition.z}.json", (chunkData) ->

      game.showChunk
        position: chunkPositionRaw
        dims: [chunkSize, chunkSize, chunkSize]
        voxels: generateChunk(chunkData, chunkPosition)

  generateChunk = (data, position) ->
    chunk = new Int8Array(chunkSize * chunkSize * chunkSize)

    if position.y is 0
      for x in [0...chunkSize]
        for z in [0...chunkSize]
          height = Math.ceil (data[Math.abs z][Math.abs x] / 255) * 32

          for y in [0..height]
            xIndex = Math.abs((chunkSize + x % chunkSize) % chunkSize)
            yIndex = Math.abs((chunkSize + y % chunkSize) % chunkSize)
            zIndex = Math.abs((chunkSize + z % chunkSize) % chunkSize)
        
            index = xIndex + (yIndex * chunkSize) + (zIndex * chunkSize * chunkSize)
            chunk[index] = 1

    chunk