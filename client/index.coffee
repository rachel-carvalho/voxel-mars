window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'

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

  $.getJSON "#{mapDir}/map.json", (map) ->
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
      lat: 0
      lng: map.center.y

    if map.generateOptions.startPosition
      poi = map.pointsOfInterest[map.generateOptions.startPosition]
      if poi
        map.center.x = ((poi.nasaFile?.x || 0) * map.width) + poi.x
        map.center.y = ((poi.nasaFile?.y || 0) * map.height) + poi.y

    fromLatLng = (latLng) ->
      {lat, lng} = latLng
      lat = parseFloat lat
      lng = parseFloat lng
      lat += 360 if lat < 0

      pos =
        x: lat * map.pixelsPerDegree
        y: -(lng * map.pixelsPerDegree) + map.latLngCenterInPx.lng

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

    origin = [map.center.x / chunkSize, 0, map.center.y / chunkSize]

    game = app.game = vengine
      materials: ['mars']
      materialFlatColor: no
      generateChunks: no
      chunkSize: chunkSize
      chunkDistance: 2
      worldOrigin: origin
      controls: {discreteFire: true}
      skyColor: 0xFA8072
      playerHeight: 3

    game.appendTo(document.body)

    avatar = vplayer(game)('astronaut.png')
    avatar.possess()
    avatar.position.set(origin[0] * chunkSize, 67, origin[2] * chunkSize)
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
    positionDiv = $('#position')
    lat = $('#lat')
    lng = $('#lng')
    alt = $('#alt')
    permalink = $('#permalink')

    position = null

    updateMidmap = (pos) ->
      pointer.css
        top: (pos.z / map.fullheight) * img.height()
        left: (pos.x / map.fullwidth) * img.width()

    toLatLngAlt = (pos) ->
      latLngAlt =
        lat: pos.x / map.pixelsPerDegree
        lng: -((pos.z - map.latLngCenterInPx.lng) / map.pixelsPerDegree)
        alt: ((pos.y - map.heightOffset - map.playerOffset) * map.metersPerVoxelVertical) - map.datum
      latLngAlt.lat -= 360 if latLngAlt.lat > 180

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
      worker.postMessage 
        cmd: 'generateChunk'
        chunkInfo: 
          heightMap: data
          position: chunkPosition
          positionRaw: chunkPositionRaw
          size: chunkSize
          heightScale: map.heightScale
          heightOffset: map.heightOffset
        ,
        [data.buffer]

    loadedZones = {}

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
