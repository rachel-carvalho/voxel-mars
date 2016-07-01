$ = require './browser/yocto.coffee'
key = require './browser/keymaster.js'

class Welcome
  constructor: ->
    @container = $('#welcome')
    @playButton = $('#welcome .play').first()
    @progressBar = $('#welcome progress').first()
    @webglIncapable = $('#welcome .webgl-incapable').first()

    @incapableState() unless @webglSupported()

    @playButton.click @hide

    @show()

  show: -> key.setScope(); @container.show()

  hide: =>
    key.setScope('game')
    @pausedState()
    @container.hide()

  setProgressMax: (max) -> @progressBar.attr {max}

  advanceProgress: ->
    if @progressBar.val() isnt @progressBar.attr('max')
      @progressBar.val @progressBar.val() + 1
      @readyState() if @progressBar.val() is @progressBar.attr('max')

  incapableState: ->
    @webglIncapable.show()
    @progressBar.hide()
    @playButton.hide()

  readyState: ->
    @progressBar.val @progressBar.attr('max')
    @playButton.attr(disabled: '').html 'Land!'

  pausedState: ->
    @progressBar.hide()
    @playButton.html 'Back'

  webglSupported: ->
    try
      cv = document.createElement('canvas')
      !! (window.WebGLRenderingContext and (cv.getContext('webgl') or cv.getContext('experimental-webgl')))
    catch ex then no

module.exports = Welcome
