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

    {chunkSize, zones} = map.generateOptions
    zones ?= {}
    zones.cols ?= 1
    zones.rows ?= 1
    zones.width = Math.round(map.width / zones.cols)
    zones.height = Math.round(map.height / zones.rows)

    origin = [map.fullwidth / 2 / chunkSize, 0, map.fullheight / 2 / chunkSize]
    origin = [5958 / chunkSize,0,3412 / chunkSize]

    game = app.game = vengine
      materials: ['mars']
      materialFlatColor: no
      generateChunks: no
      chunkSize: chunkSize
      chunkDistance: 2
      worldOrigin: origin
      controls: {discreteFire: true}
      skyColor: 0xFA8072

    game.appendTo(document.body)

    avatar = vplayer(game)('astronaut.png')
    avatar.possess()
    avatar.position.set(origin[0] * chunkSize, 100, origin[2] * chunkSize)
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

    loadedZones = {}

    renderChunk = (ctx, imgPosition, chunkPosition, chunkPositionRaw) ->
      data = ctx.getImageData(imgPosition.x, imgPosition.z, chunkSize, chunkSize).data
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

    game.voxels.on 'missingChunk', (chunkPositionRaw) ->
      chunkPosition = x: chunkPositionRaw[0], y: chunkPositionRaw[1], z: chunkPositionRaw[2]

      {zone, relativePosition} = convertChunkToZone chunkPosition

      zone.key = "x#{zone.x}/y#{zone.z}"

      if loadedZones[zone.key]
        if loadedZones[zone.key].loading
          loadedZones[zone.key].toRender.push {relativePosition, chunkPosition, chunkPositionRaw}
        else
          renderChunk loadedZones[zone.key].ctx, relativePosition, chunkPosition, chunkPositionRaw
      else
        loadedZones[zone.key] =
          x: zone.x
          z: zone.z
          loading: yes
          toRender: [{relativePosition, chunkPosition, chunkPositionRaw}]

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
            renderChunk ctx, relativePosition, chunkPosition, chunkPositionRaw
          loadedZones[zone.key].toRender = []
          
        hmImg.src = "#{mapDir}/zones/#{zone.key}.png"

    worker.addEventListener 'message', (e) ->
      switch e.data.event
        when 'log'
          console.log e.data.msg
        when 'chunkGenerated'
          game.showChunk
            position: e.data.chunk.position
            dims: [chunkSize, chunkSize, chunkSize]
            voxels: e.data.chunk.voxels
