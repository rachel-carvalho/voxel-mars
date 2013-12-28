class NavMap
  constructor: (@map) ->
      @container = $('#map')
      @img = $('#map img')
      @vertical = $('#vertical')
      @horizontal = $('#horizontal')

      @container.click (e) =>
        if @container.hasClass 'global'
          @onGlobalClick e


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


  toggle: (position) ->
    @container.toggleClass('mini').toggleClass('global')
    @update position


  onGlobalClick: (e) ->
    pos = @map.fromTopLeft {top: e.pageY, left: e.pageX}, @img.width(), @img.height()

    latLng = @map.toLatLngAlt pos

    location.hash = "#lat=#{latLng.lat}&lng=#{latLng.lng}"
    location.reload()


module.exports = NavMap