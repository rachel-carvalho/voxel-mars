express = require 'express'
fs = require 'fs'
{PNG} = require 'pngjs'
browserify = require 'browserify-middleware'

global.log = console.log

app = express()

app.set 'view engine', 'jade'

app.locals require('./locals')

app.use express.static "#{__dirname}/public"

for name in 'index worker'.split ' '
  app.use "/js/#{name}.js", browserify "./client/#{name}.coffee", transform: ['coffeeify']

port = process.env.PORT || 3000
app.listen port, -> log "App started on port #{port}"
