class Coords
  constructor: (@world, type, input) ->
    @setType(type)
    @set(input) if input

  set: (input) ->
    this[@a] = parseFloat (input[@a] ? input[0])
    this[@b] = parseFloat (input[@b] ? input[1])

    this

  parse: (input) -> @set(input.split(',')); this
 
  setType: (@type) ->
    if @type is 'latlng' then [@a, @b] = ['lat', 'lng']
    else [@a, @b] = ['x', 'z']

    this

  clone: -> new Coords @world, @type, this

  multiply: (factor) ->
    this[@a] = Math.floor(this[@a] * factor)
    this[@b] = Math.floor(this[@b] * factor)

    this
  
  divide: (factor) ->
    this[@a] = Math.floor(this[@a] / factor)
    this[@b] = Math.floor(this[@b] / factor)

    this

  toVoxely: ->
    switch @type
      when 'voxely' then @clone()
      when 'threely' then @clone().divide(@world.voxelSize).setType('voxely')
      when 'chunky' then @clone().multiply(@world.chunkSize).setType('voxely')
      when 'zoney'
        zoney = @clone()
        zoney.x = Math.floor(zoney.x * @world.zoneWidth)
        zoney.z = Math.floor(zoney.z * @world.zoneHeight)
        zoney.setType('voxely')
      when 'latlng'
        {pixelsPerDegree, origin} = @world

        @lng += 360 if @lng < 0

        new Coords @world, 'voxely',
          x: (@lng * pixelsPerDegree) + origin.x
          z: -(@lat * pixelsPerDegree) + origin.z

  # performance shortcut for world.getY
  @voxelyToZoneyString: (w, x, z) -> "#{Math.floor x / w.zoneWidth},#{Math.floor z / w.zoneHeight}"

  toThreely: -> @toVoxely().multiply(@world.voxelSize).setType('threely')
  toChunky: -> @toVoxely().divide(@world.chunkSize).setType('chunky')
  toZoney: ->
    voxely = @toVoxely()
    voxely.x = Math.floor(voxely.x / @world.zoneWidth)
    voxely.z = Math.floor(voxely.z / @world.zoneHeight)
    voxely.setType('zoney')
  toLatLng: ->
    voxely = @toVoxely()
    
    lat = -((voxely.z - @world.origin.z) / @world.pixelsPerDegree)
    lng = voxely.x / @world.pixelsPerDegree
    lng -= 360 if lng > 180
    # alt = ((pos.y - @heightOffset - @playerOffset) * @metersPerVoxelVertical) - @datum

    new Coords @world, 'latlng', {lat, lng}

  toString: -> "#{this[@a]},#{this[@b]}"

module.exports = Coords