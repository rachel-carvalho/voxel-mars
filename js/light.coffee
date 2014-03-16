THREE = require './three/three-r65.js'

class Light
  constructor: (@scene, @renderer, @clock) ->
    @minBrightness = 0

    @fog = @scene.fog.color.clone()
    @directional = @scene.directionalLight.color.clone()
    @ambient = @scene.ambientLight.color.clone()
    @sky = @renderer.getClearColor().clone()

  setColorBrightness: (color, reference, factor) ->
    color.r = reference.r * factor
    color.g = reference.g * factor
    color.b = reference.b * factor
    color

  setBrightness: (factor) ->
    @setColorBrightness @scene.fog.color, @fog, factor
    @setColorBrightness @scene.directionalLight.color, @directional, factor
    @setColorBrightness @scene.ambientLight.color, @ambient, factor
    @scene.ambientLight.visible = factor > 0
    @scene.headLamp.visible = factor < 0.4
    @renderer.setClearColor @setColorBrightness(new THREE.Color(), @sky, factor)

  update: ->
    hour = @clock.getHour()
    secsInHour = 60 * 60
    gameSecs = @clock.getElapsedGameSecs()
    ratio = (gameSecs % secsInHour) / secsInHour

    switch
      when 6 < hour < 18 then @setBrightness(1)
      when hour is 6 then @setBrightness(Math.max @minBrightness, ratio)
      when hour is 18 then @setBrightness(Math.max @minBrightness, Math.abs(1 - ratio))
      else @setBrightness(@minBrightness)

module.exports = Light