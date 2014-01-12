class NavMap
  constructor: (@map) ->
    @container = $('#map')
    @img = $('#map img')
    @vertical = $('#vertical')
    @horizontal = $('#horizontal')
    @lastPosition = null
    @updateTitle()

    @container.click (e) =>
      if @global()
        @onGlobalClick e
      else if @mini()
        @onMiniClick e


  global: ->
    @container.hasClass 'global'


  mini: ->
    @container.hasClass 'mini'


  update: (pos) ->
    height = @img.height()
    width = @img.width()

    {top, left} = @map.toTopLeft pos, width, height

    if @mini()
      border = parseInt(@container.css('border-left-width'), 10)
      half = (@container.width() / 2) - border
      
      @img.css
        marginLeft: -left + half
        marginTop: -top + half

      left = top = half

    else
      @img.css marginLeft: 0, marginTop:0

    @horizontal.css {top, width}
    @vertical.css {left, height}


  updateTitle: ->
    title = if @global() then 'click to teleport to location (page will be reloaded)' else 'click to open global map'
    @container.attr 'title', title


  toggle: (position) ->
    @lastPosition = position
    @container.toggleClass('mini').toggleClass('global')
    @updateTitle()
    @update position


  onGlobalClick: (e) ->
    pos = @map.fromTopLeft {top: e.pageY, left: e.pageX}, @img.width(), @img.height()

    latLng = @map.toLatLngAlt pos

    location.hash = "#lat=#{latLng.lat}&lng=#{latLng.lng}"
    location.reload()


  onMiniClick: (e) ->
    @toggle @lastPosition


  setPosition: (pos) ->
    @lastPosition = pos

module.exports = NavMap