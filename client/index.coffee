window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'

worker = app.worker = new Worker '/js/worker.js'

$ ->
  {map} = app

  {chunkSize} = map

  game = app.game = vengine
    materials: ['mars.png']
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

  updateMidmap = (pos) ->
    pointer.css
      top: ((map.center.y + Math.floor pos.z) / map.height) * img.height()
      left: ((map.center.x + Math.floor pos.x) / map.width) * img.width()

  game.voxelRegion.on 'change', (pos) ->
    updateMidmap x: pos[0], y: pos[1], z: pos[2]

  $(window).keydown (ev) ->
    if ev.keyCode is 'M'.charCodeAt(0)
      pos = target.position

      div.toggle()

      updateMidmap pos

  game.voxels.on 'missingChunk', (chunkPositionRaw) ->
    chunkPosition = x: chunkPositionRaw[0], y: chunkPositionRaw[1], z: chunkPositionRaw[2]
    
    $.getJSON "/map/#{chunkPosition.x}/#{chunkPosition.z}.json", (heightMap) ->
      worker.postMessage 
        cmd: 'generateChunk'
        chunkInfo: 
          heightMap: heightMap
          position: chunkPosition
          positionRaw: chunkPositionRaw
          size: chunkSize
          heightScale: map.heightScale


  worker.addEventListener 'message', (e) ->
    switch e.data.event
      when 'log'
        console.log e.data.msg
      when 'chunkGenerated'
        game.showChunk
          position: e.data.chunk.position
          dims: [chunkSize, chunkSize, chunkSize]
          voxels: e.data.chunk.voxels
