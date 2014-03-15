express = require 'express'
browserify = require 'browserify-middleware'
stylus = require 'stylus'
fs = require 'fs'

app = express()

app.set 'views', __dirname

app.use express.static "#{__dirname}/static"
app.use '/world', express.static "#{__dirname}/world/static"
app.use '/world', express.static "#{__dirname}/world/out"

app.use '/js/index.js', browserify "#{__dirname}/js/index.coffee", transform: ['coffeeify']

app.use '/css/index.css', (req, res) ->
  fs.readFile "#{__dirname}/css/index.styl", (err, content) ->
    if err then res.send JSON.stringify err
    else
      stylus.render content.toString(), {paths: ["#{__dirname}/css"]}, (err, css) ->
        if err then res.send err.message
        else res.type 'css'; res.send css

app.get '/', (req, res) ->
  res.render 'html/index.jade', {js: 'index.js', css: 'index.css'}

port = process.env.PORT || 3000
app.listen port, -> console.log "Server started on port #{port}"