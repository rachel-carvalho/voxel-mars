express = require 'express'
fs = require 'fs'
{PNG} = require 'pngjs'
browserify = require 'browserify-middleware'

global.log = console.log

fs.createReadStream('./public/maps/mars.png').pipe(new PNG filterType: 4).on 'parsed', ->
  heightmap = {@width, @height, @data}

  chunkSize = 32

  center = {x: heightmap.width / 2, y: heightmap.height / 2}
  olympus_mons = {x: 7319, y: 2443}
  noctis_labyrinthus = {x: 8403, y: 3067}
  center = olympus_mons

  app = express()

  app.use '/js/index.js', browserify './client.coffee', transform: ['coffeeify']
  app.use express.static "#{__dirname}/public"

  app.get '/center', (req, res) ->
    res.send JSON.stringify(center)

  app.get '/map/:x/:y.json', (req, res) ->
    start =
      x: center.x + (Number(req.params.x) * chunkSize)
      y: center.y + (Number(req.params.y) * chunkSize)
      
    chunk = []

    for y in [(start.y)...(start.y + chunkSize)]
      chunk[y - start.y] = []
      for x in [(start.x)...(start.x + chunkSize)]
        # << = left shift operator
        idx = (heightmap.width * y + x) << 2
        chunk[y - start.y][x - start.x] = heightmap.data[idx]

    res.send JSON.stringify(chunk)

  port = process.env.PORT || 3000
  app.listen port, -> log "App started on port #{port}"