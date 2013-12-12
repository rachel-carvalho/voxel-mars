window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'

window.app = {}

worker = app.worker = new Worker '/js/worker.js'

mapDir = 'maps/mars'

$ ->
  $.getJSON "#{mapDir}/map.json", (map) ->
    app.map = map
    map.heightScale = map.deltaY / map.metersPerPixel
    # TODO: calculate center from chosen POI
    map.cols ?= 1
    map.rows ?= 1
    map.fullwidth = map.width * map.cols
    map.fullheight = map.height * map.rows
    map.center = {x: map.fullwidth / 2, y: map.fullheight / 2}

    {chunkSize} = map.generateOptions

    game = app.game = vengine
      materials: ['mars']
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
    avatar.position.set(0, 50, 0)
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
        top: ((map.center.y + Math.floor pos.z) / map.fullheight) * img.height()
        left: ((map.center.x + Math.floor pos.x) / map.fullwidth) * img.width()

    game.voxelRegion.on 'change', (pos) ->
      updateMidmap x: pos[0], y: pos[1], z: pos[2]

    $(window).keydown (ev) ->
      if ev.keyCode is 'M'.charCodeAt(0)
        div.toggle()

        updateMidmap target.position

    game.voxels.on 'missingChunk', (chunkPositionRaw) ->
      chunkPosition = x: chunkPositionRaw[0], y: chunkPositionRaw[1], z: chunkPositionRaw[2]

      hmImg = new Image()
      hmImg.onload = ->
        canvas = document.createElement 'canvas'
        canvas.width = chunkSize
        canvas.height = chunkSize
        ctx = canvas.getContext '2d'
        ctx.drawImage this, 0, 0
        data = ctx.getImageData(0, 0, chunkSize, chunkSize).data
        worker.postMessage 
          cmd: 'generateChunk'
          chunkInfo: 
            heightMap: data
            position: chunkPosition
            positionRaw: chunkPositionRaw
            size: chunkSize
            heightScale: map.heightScale
          ,
          [data.buffer]

      hmImg.src = "#{mapDir}/chunks/x#{chunkPosition.x}/y#{chunkPosition.z}.png"

    worker.addEventListener 'message', (e) ->
      switch e.data.event
        when 'log'
          console.log e.data.msg
        when 'chunkGenerated'
          game.showChunk
            position: e.data.chunk.position
            dims: [chunkSize, chunkSize, chunkSize]
            voxels: e.data.chunk.voxels
