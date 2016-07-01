$ = require './browser/yocto.coffee'

class NavMaps
  constructor: (@world) ->
    @container = $('.nav-maps').first()
    @img = $('.nav-maps img').first()
    @vertical = $('.nav-maps .vertical').first()
    @horizontal = $('.nav-maps .horizontal').first()

    @container.click @click

  toggle: ->
    if @global
      @global = no
      @container.el.classList.remove 'global'
      @container.el.classList.add 'mini'
    else
      @global = yes
      @container.el.classList.remove 'mini'
      @container.el.classList.add 'global'

  click: (e) =>
    if not @global
      @toggle()
      e.stopPropagation()
    else
      pos = @world.voxely(x: e.pageX / @img.width() * @world.width, z: e.pageY / @img.height() * @world.height).toLatLng()
      window.location = "#lat=#{pos.lat}&lng=#{pos.lng}"
      window.location.reload()

  update: (pos) ->
    if not @lastUpdate or +new Date() - @lastUpdate > 100
      @lastUpdate = +new Date()

      {width, height} = @img.el
      {voxelSize} = @world

      top = Math.floor(pos.z / voxelSize) / @world.height * height
      left = Math.floor(pos.x / voxelSize) / @world.width * width

      if @global then @img.css marginLeft: 0, marginTop: 0
      else
        half = @container.width() / 2
        @img.css marginTop: -top + half, marginLeft: -left + half
        left = top = half

      @horizontal.css {top, width}
      @vertical.css {left, height}

module.exports = NavMaps
