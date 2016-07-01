util = require './util.coffee'

class Zone
  constructor: (@world, @position, cb) ->
    @loading = yes

    util.loadImage "/world/height/x#{@position.x}/y#{@position.z}.png", (img) =>
      @data = @getImageData(img)

      @loading = no
      cb(this) if cb

  getImageData: (img) ->
    canvas = document.createElement 'canvas'
    canvas.width = img.width
    canvas.height = img.height
    ctx = canvas.getContext '2d'
    ctx.drawImage img, 0, 0
    ctx.getImageData(0, 0, img.width, img.height).data

  getHeight: (x, z) ->
    {zoneWidth, zoneHeight, heightScale} = @world

    local = x: x % zoneWidth, z: z % zoneHeight

    i = (zoneWidth * local.z + local.x) << 2
    Math.ceil (@data[i] / 255) * heightScale

module.exports = Zone
