$ = require './browser/yocto.coffee'

class InfoPanel
  constructor: (@clock, @world) ->
    @sol = $('.info-panel .sol .value').first()
    @time = $('.info-panel .time .value').first()
    @alt = $('.info-panel .alt .value').first()
    @lat = $('.info-panel .lat .value').first()
    @lng = $('.info-panel .lng .value').first()

  update: (threely) ->
    if not @lastUpdate or +new Date() - @lastUpdate > 100
      @lastUpdate = +new Date()

      voxely = y: Math.floor threely.y / @world.voxelSize
      latlng = @world.threely(threely).toLatLng()

      @sol.html @clock.getSol()
      @time.html @clock.getTimeString()

      @alt.html Math.round((voxely.y * @world.metersPerVoxelVertical) - @world.datum) + ' m'
      @lat.html latlng.lat.toFixed(7)
      @lng.html latlng.lng.toFixed(7)

module.exports = InfoPanel
