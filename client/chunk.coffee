common = require './common.coffee'
worker = require './worker.coffee'
blobURL = window.URL.createObjectURL(new Blob(["
  var getHeightFromColor = (#{common.getHeightFromColor});
  (#{worker})();
  "]))

WorkCrew = require '../public/js/workcrew.js'

class Chunk
  @loadedZones = {}

  @crew = new WorkCrew blobURL, 2

  @underWork = {}

  @loading = {}

  constructor: (opts) ->
    {@map, coords, @game, @lp, @onRender} = opts

    @rawCoords = coords

    @key = @rawCoords.join ','

    if Chunk.loading[@key]
      log "already working on chunk #{@key}"
    else
      Chunk.loading[@key] = this

      @coords = @map.toPositionChunk coords

      @mapDir = "maps/#{@map.name}"

      @load()


  # loads zone png and calls `generate`
  load: ->
    {@zone, @relativePosition} = @map.findZoneByChunk @coords

    @zone.key = "x#{@zone.x}/y#{@zone.z}"

    loadedZones = Chunk.loadedZones

    if loadedZones[@zone.key]
      @zone = loadedZones[@zone.key]
      if loadedZones[@zone.key].loading
        loadedZones[@zone.key].toGenerate.push this
      else
        @generate()
    else
      loadedZones[@zone.key] = @zone
      @zone.loading = yes
      @zone.toGenerate = [this]
      @zone.img = new Image()

      self = this

      @zone.img.onload = ->
        self.zone.canvas = canvas = document.createElement 'canvas'
        canvas.width = self.map.zones.width
        canvas.height = self.map.zones.height
        self.zone.ctx = ctx = canvas.getContext '2d'
        ctx.drawImage this, 0, 0
        self.zone.loading = no
        
        for chunk in self.zone.toGenerate
          chunk.generate()
        self.zone.toGenerate = []
        
      @zone.img.src = "#{@mapDir}/zones/#{@zone.key}.png"


  # extracts data from the png and sends it to worker
  generate: ->
    data = @zone.ctx.getImageData(@relativePosition.x, @relativePosition.z, @map.chunkSize, @map.chunkSize).data

    chunkInfo =
      heightMap: data.buffer
      position: @coords
      positionRaw: @rawCoords
      size: @map.chunkSize
      heightScale: @map.heightScale
      heightOffset: @map.heightOffset

    if Chunk.underWork[@key]
      log "crew is working on it: #{@key}"
    else
      Chunk.underWork[@key] = this

      Chunk.crew.addWork
        id: @key
        msg: 
          cmd: 'generateChunk'
          chunkInfo: chunkInfo
        transferables: [data.buffer]


  # renders the generated voxels
  render: ->
    @lp.update()

    @game.showChunk
      position: @rawCoords
      dims: (@map.chunkSize for i in [1..3])
      voxels: @voxels
      

    if typeof @onRender is 'function'
      @onRender()


  # when worker is finished, we call `chunk.render`
  @onWorkComplete: (r) ->
    e = r.result
    
    switch e.data.event
      when 'log'
        log e.data.msg
      
      when 'chunkGenerated'
        key = e.data.chunk.position.join ','

        chunk = Chunk.underWork[key]

        if not chunk
          log "ops, chunk not found: #{key}"
        else
          delete Chunk.underWork[key]
          delete Chunk.loading[key]

          chunk.voxels = new Int8Array e.data.chunk.voxels

          chunk.render()


  @crew.oncomplete = @onWorkComplete


module.exports = Chunk
