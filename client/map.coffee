class Map
  constructor: (data) ->
    {
      @name
      @width
      @height
      @metersPerPixel
      @pixelsPerDegree
      @datum
      @deltaY
      @heightScale
      @cols
      @rows
      @latLngCenter
      @renderOptions
      @pointsOfInterest
    } = data

    {
      @startPosition
      @chunkSize
      @zones
    } = @renderOptions

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

    # width/height of a zone png
    @zones.width = Math.round(@width / @zones.cols)
    @zones.height = Math.round(@height / @zones.rows)

    # width and height of map in chunks 
    @chunks = 
      width: Math.ceil(@fullwidth / @chunkSize)
      height: Math.ceil(@fullheight / @chunkSize)

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


module.exports = Map