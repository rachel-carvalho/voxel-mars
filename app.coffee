express = require 'express'
fs = require 'fs'
{PNG} = require 'pngjs'
browserify = require 'browserify-middleware'

global.log = console.log

map = name: 'mars'

fs.createReadStream("./public/maps/#{map.name}.png").pipe(new PNG filterType: 4).on 'parsed', ->
  map.width = @width
  map.height = @height
  map.data = @data

  chunkSize = 32

  map.center = {x: map.width / 2, y: map.height / 2}
  olympus_mons = {x: 7319, y: 2443}
  noctis_labyrinthus = {x: 8403, y: 3067}
  map.center = olympus_mons

  app = express()

  app.set 'view engine', 'jade'

  app.locals require('./locals')

  app.use '/js/index.js', browserify './client.coffee', transform: ['coffeeify']
  app.use express.static "#{__dirname}/public"

  app.get '/', (req, res) ->
    res.render 'index', {map}

  app.get '/map/:x/:y.json', (req, res) ->
    start =
      x: map.center.x + (Number(req.params.x) * chunkSize)
      y: map.center.y + (Number(req.params.y) * chunkSize)
      
    chunk = []

    for y in [(start.y)...(start.y + chunkSize)]
      chunk[y - start.y] = []
      for x in [(start.x)...(start.x + chunkSize)]
        # << = left shift operator
        idx = (map.width * y + x) << 2
        chunk[y - start.y][x - start.x] = map.data[idx]

    res.send JSON.stringify(chunk)

  port = process.env.PORT || 3000
  app.listen port, -> log "App started on port #{port}"