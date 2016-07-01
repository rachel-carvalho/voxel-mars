Mesher = require './mesher.coffee'

class Chunk
  constructor: (@world, @position, cb) ->
    {voxelSize, chunkSize} = @world

    Chunk.mesher ?= new Mesher(voxelSize, chunkSize)

    startZ = @position.z * chunkSize
    startX = @position.x * chunkSize

    endZ = startZ + chunkSize
    endX = startX + chunkSize

    @mesh = Chunk.mesher.generate
      zArray: [startZ...endZ]
      xArray: [startX...endX]
      getY: (x, z) => @world.getY(x, z)

    cb(this) if cb

  delete: ->
    @mesh.geometry.dispose()
    delete @mesh.data
    delete @mesh.geometry
    delete @mesh.meshed
    delete @mesh

module.exports = Chunk
