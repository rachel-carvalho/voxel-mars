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

    @fullwidth = @width * @cols
    @fullheight = @height * @rows
    @center = {x: @fullwidth / 2, z: @fullheight / 2}
    
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
      width: Math.ceil(@fullwidth / @chunkSize)
      height: Math.ceil(@fullheight / @chunkSize)

    # constants:

    # all heights are added one to avoid holes at altitude 0
    @heightOffset = 1
    # player is one voxel on top of the floor
    @playerOffset = 1


  getOrigin: ->
    [Math.floor(@startPoint.x / @chunkSize), 0, Math.floor(@startPoint.z / @chunkSize)]


  textToPixel: (text, coord) ->
    widthHeight = if coord is 'x' then 'width' else 'height'
    if text is 'left' or text is 'top'
      0
    else if text is 'center'
      @center[coord]
    else if text is 'right' or text is 'bottom'
      @["full#{widthHeight}"]


  fromLatLng: (latLng) ->
    {lat, lng} = latLng
    lat = parseFloat lat
    lng = parseFloat lng
    lng += 360 if lng < 0

    pos =
      x: (lng * @pixelsPerDegree) + @latLngCenterInPx.lng
      z: -(lat * @pixelsPerDegree) + @latLngCenterInPx.lat

    pos


  toLatLngAlt: (pos) ->
    latLngAlt =
      lat: -((pos.z - @latLngCenterInPx.lat) / @pixelsPerDegree)
      lng: pos.x / @pixelsPerDegree
      alt: ((pos.y - @heightOffset - @playerOffset) * @metersPerVoxelVertical) - @datum
    latLngAlt.lng -= 360 if latLngAlt.lng > 180

    latLngAlt


  convertChunkToZone: (chunkPosition) ->
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


  toPositionChunk: (arr) ->
    x: mod arr[0], @chunks.width
    y: arr[1]
    z: arr[2]


  toPositionPoint: (arr) ->
    x: mod arr[0], @fullwidth
    y: arr[1]
    z: arr[2]

  toTopLeft: (pos, width, height) ->
    top: (pos.z / @fullheight) * height
    left: (pos.x / @fullwidth) * width


  fromTopLeft: (pos, width, height) ->
    x: (pos.left / width) * @fullwidth
    z: (pos.top / height) * @fullheight


mod = (num, m) ->
  ((num % m) + m) % m

module.exports = Map