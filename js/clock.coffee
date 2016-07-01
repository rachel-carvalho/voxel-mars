THREE = require './three/three-r65.js'

class Clock
  constructor: ->
    # real minutes per game sol
    @minutesPerSol = 24
    @startingHour = 7

    @threeClock = new THREE.Clock()

  getDelta: -> @threeClock.getDelta()

  getElapsedGameSecs: -> @threeClock.getElapsedTime() / (@minutesPerSol / 24 / 60)
  getElapsedGameMins: -> @getElapsedGameSecs() / 60
  getElapsedGameHours: -> (@getElapsedGameMins() / 60) + @startingHour

  getSol: -> Math.floor @getElapsedGameHours() / 24
  getHour: -> Math.floor @getElapsedGameHours() % 24
  getMinutes: -> Math.floor @getElapsedGameMins() % 60

  getTimeString: ->
    hour = @getHour()
    minutes = @getMinutes()

    hour = "0#{hour}" if hour < 10
    minutes = "0#{minutes}" if minutes < 10

    "#{hour}:#{minutes}"

module.exports = Clock
