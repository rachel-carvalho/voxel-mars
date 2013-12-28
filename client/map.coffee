class Map
  constructor: (data) ->
    {
      @name, @width, @height, @metersPerPixel, @pixelsPerDegree
      @datum, @deltaY, @heightScale, @cols, @rows
      @latLngCenter, @pointsOfInterest
      @startPosition, @chunkSize, @zones
      @chunkDistance, @skyColor
    } = data

    # defaults
    @cols ?= 1
    @rows ?= 1
    @heightScale ?= @deltaY / @metersPerPixel
    @zones.cols ?= 1
    @zones.rows ?= 1

    # calculations
    # different from @metersPerPixel in case heightScale has been manually set
    @metersPerVoxelVertical = @deltaY / @heightScale

    @fullWidth = @width * @cols
    @fullHeight = @height * @rows
    @center = {x: @fullWidth / 2, z: @fullHeight / 2}
    
    # which pixel represents lat/lng zero
    @latLngCenterInPx =
      lat: @textToPixel @latLngCenter.lat, 'z'
      lng: @textToPixel @latLngCenter.lng, 'x'

    # sets lat/lng of startposition based on POI
    if @startPosition
      poi = @pointsOfInterest[@startPosition]
      @startPoint = @fromLatLng(poi) if poi
    else
      @startPoint = @center

    # width/height of a zone png
    @zones.width = Math.round(@width / @zones.cols)
    @zones.height = Math.round(@height / @zones.rows)

    # width and height of map in chunks 
    @chunks = 
      width: Math.ceil(@fullWidth / @chunkSize)
      height: Math.ceil(@fullHeight / @chunkSize)

    # constants:

    # all heights are added one to avoid holes at altitude 0
    @heightOffset = 1
    # player is one voxel on top of the floor
    @playerOffset = 1


  # chunk in which player spawns
  getOrigin: ->
    [Math.floor(@startPoint.x / @chunkSize), 0, Math.floor(@startPoint.z / @chunkSize)]


  # translates anchor point to map X/Z values
  textToPixel: (anchor, axis) ->
    widthHeight = if axis is 'x' then 'Width' else 'Height'
    switch anchor
      when 'left', 'top'
        0
      when 'center'
        @center[axis]
      when 'right', 'bottom'
        @["full#{widthHeight}"]


  # translates latitude/longitude to voxel coordinates
  fromLatLng: (latLng) ->
    {lat, lng} = latLng
    lat = parseFloat lat
    lng = parseFloat lng
    lng += 360 if lng < 0

    pos =
      x: (lng * @pixelsPerDegree) + @latLngCenterInPx.lng
      z: -(lat * @pixelsPerDegree) + @latLngCenterInPx.lat

    pos


  # translates voxel coordinates to latitude/longitude
  toLatLngAlt: (pos) ->
    latLngAlt =
      lat: -((pos.z - @latLngCenterInPx.lat) / @pixelsPerDegree)
      lng: pos.x / @pixelsPerDegree
      alt: ((pos.y - @heightOffset - @playerOffset) * @metersPerVoxelVertical) - @datum
    latLngAlt.lng -= 360 if latLngAlt.lng > 180

    latLngAlt


  # finds X/Z for zone and inside zone image, X/Z for a given chunk
  findZoneByChunk: (chunkPosition) ->
    pixelPos = 
      x: chunkPosition.x * @chunkSize
      z: chunkPosition.z * @chunkSize
    
    zone =
      x: Math.floor(pixelPos.x / @zones.width)
      z: Math.floor(pixelPos.z / @zones.height)

    relativePosition =
      x: pixelPos.x % @zones.width
      z: pixelPos.z % @zones.height

    {zone, relativePosition}


  # converts chunk coord array into absolute coord object
  toPositionChunk: (arr) ->
    x: mod arr[0], @chunks.width
    y: arr[1]
    z: arr[2]


  # converts voxel coord array into absolute coord object
  toPositionPoint: (arr) ->
    x: mod arr[0], @fullWidth
    y: arr[1]
    z: arr[2]


  # converts voxel coord object to css top left coords, based on element width/height
  toTopLeft: (pos, width, height) ->
    top: (pos.z / @fullHeight) * height
    left: (pos.x / @fullWidth) * width


  # converts css top left coords to voxel coord object, based on element width/height
  fromTopLeft: (pos, width, height) ->
    x: (pos.left / width) * @fullWidth
    z: (pos.top / height) * @fullHeight


mod = (num, m) ->
  ((num % m) + m) % m

module.exports = Map