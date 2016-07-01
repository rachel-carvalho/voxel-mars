data = require '../world/world.coffee'

qs = require './browser/querystring.coffee'

Coords = require './coords.coffee'
Zone = require './zone.coffee'
Chunk = require './chunk.coffee'

class World
  constructor: (@game, @handlers) ->
    @timeout = 20 # max time to spend processing the todo list on each step
    @rest = 0 # how long to wait before tackling the todo list again
    @stableRest = 500 # rest value after clearing the todo list for the first time

    @voxelSize = 100 # threely
    @chunkSize = 32 # voxely
    @chunkDistance = 3 # chunky

    {
      @name, @metersPerPixel, @pixelsPerDegree, @width, @height, @cols, @rows
      @datum, @heightSpan, @heightScale, @origin, @start
    } = data

    query = qs.parse()
    @start = query if query.lat and query.lng

    @heightScale ?= @heightSpan / @metersPerPixel

    # different from @metersPerPixel in case heightScale has been manually set
    @metersPerVoxelVertical = @heightSpan / @heightScale

    @zoneWidth = Math.round(@width / @cols) # voxely
    @zoneHeight = Math.round(@height / @rows) # voxely

    @chunks = {}
    @zones = {}

    @todo = []

    @createZone @latLng(@start).toZoney(), @handlers.firstZoneCreated

  latLng: (input) -> new Coords(this, 'latlng', input)
  threely: (input) -> new Coords(this, 'threely', input)
  voxely: (input) -> new Coords(this, 'voxely', input)
  chunky: (input) -> new Coords(this, 'chunky', input)
  zoney: (input) -> new Coords(this, 'zoney', input)

  getY: (x, z) ->
    # too slow: `zone = @zones[@voxely({x, z}).toZoney().toString()]`
    zone = @zones[Coords.voxelyToZoneyString this, x, z]

    if not zone
      # TODO: fake shadows require getY for bordering voxels in neighbour zones,
      # but currently a zone is only loaded when it's within chunkDistance
      log 'zone not found', {x, z, zoney: Coords.voxelyToZoneyString this, x, z}
      0
    else zone.getHeight(x, z)

  getAvatarY: (x, z) ->
    (@getY(x, z) + 0.5) * @voxelSize

  update: (currentThreelyPosition) ->
    newp = @threely(currentThreelyPosition).toChunky()
    oldp = @currentChunkyPosition

    # if chunky position changed
    if not oldp or oldp.x isnt newp.x or oldp.z isnt newp.z
      @currentChunkyPosition = newp
      oldp ?= newp

      @updateTodo(oldp, newp)

    @executeTodo()

  updateTodo: (oldp, newp) ->
    cd = @chunkDistance

    # all chunks within chunkDistance from the old and new positions
    for x in [Math.min(oldp.x - cd, newp.x - cd)..Math.max(oldp.x + cd, newp.x + cd)]
      for z in [Math.min(oldp.z - cd, newp.z - cd)..Math.max(oldp.z + cd, newp.z + cd)]
        chunkKey = @chunky({x, z}).toString()
        # if chunk is outside of the chunkDistance
        if x < newp.x - cd or x > newp.x + cd or z < newp.z - cd or z > newp.z + cd
          @todo.push [chunkKey, 'delete']
        else
          @todo.push [chunkKey, 'create']

    if not @handlers.firstTodo.called
      @handlers.firstTodo.called = yes
      @handlers.firstTodo(@todo.length)

  executeTodo: ->
    if @todo.length is 0 then @rest = @stableRest
    else if not @lastTodoExecution or +new Date() - @lastTodoExecution > @rest
      start = +new Date()

      while @todo.length > 0 and (+new Date() - start) < @timeout
        [chunkKey, value] = @todo.shift()

        chunky = @chunky().parse(chunkKey)

        switch value
          when 'delete' then @deleteChunk(chunky)
          when 'create'
            zone = @zones[chunky.toZoney().toString()]

            if not zone then @createZone chunky.toZoney()
            else if not zone.loading then @createChunk(chunky)

      @lastTodoExecution = +new Date()

  createZone: (position, cb) ->
    key = position.toString()

    if not @zones[key]
      @zones[key] = zone = new Zone this, position, ->
        cb(zone) if cb

  createChunk: (position) ->
    key = position.toString()

    if not @chunks[key]
      @chunks[key] = new Chunk this, position, (chunk) =>
        @game.scene.add chunk.mesh
        @handlers.chunkCreated?(position)

  deleteChunk: (position) ->
    key = position.toString()

    chunk = @chunks[key]
    if chunk
      @game.scene.remove chunk.mesh
      delete @chunks[key]
      chunk.delete()

module.exports = World
