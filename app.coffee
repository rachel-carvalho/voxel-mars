express = require 'express'
browserify = require 'browserify-middleware'

app = express()

app.use express.static "#{__dirname}/public"

for name in 'index worker'.split ' '
  app.use "/js/#{name}.js", browserify "./client/#{name}.coffee", transform: ['coffeeify']

port = process.env.PORT || 3000
app.listen port, -> console.log "App started on port #{port}"
