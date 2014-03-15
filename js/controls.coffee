$ = require './browser/yocto.coffee'
PointerLock = require './browser/pointer-lock.coffee'
key = require './browser/keymaster.js'

class Controls
  constructor: (@game, @element, @camera) ->
    @pointerLock = new PointerLock(@element.el)
    @pointerLockHelp = $('.pointer-lock-help').first()
    @help = $('.extended-help').first()

    # todo: request fullscreen first for firefox
    @element.click => @pointerLock.request() unless @pointerLock.locked()
    @pointerLock.on change: @onPointerLockChange

    @element.on mousemove: @onMouseMove

    key 'h', 'game', => @help.toggle()
    key 'm', 'game', => @game.navMaps.toggle()
    key '/', 'game', => @game.toggleDebug()
    key 'esc', 'game', => @game.welcome.show() unless @pointerLock.locked()

  movingForward: -> key.getScope() is 'game' and (key.isPressed('up') or key.isPressed('w'))
  movingLeft: -> key.getScope() is 'game' and (key.isPressed('left') or key.isPressed('a'))
  movingBackward: -> key.getScope() is 'game' and (key.isPressed('down') or key.isPressed('s'))
  movingRight: -> key.getScope() is 'game' and (key.isPressed('right') or key.isPressed('d'))

  jumping: -> (key.getScope() is 'game') and key.isPressed 'space'

  onPointerLockChange: =>
    if @pointerLock.locked() then @pointerLockHelp.hide() else @pointerLockHelp.show()

  onMouseMove: (event) =>
    if @pointerLock.locked()
      {x, y} = @pointerLock.getMovement(event)

      @camera.yaw.rotation.y -= x * 0.002
      @camera.pitch.rotation.x -= y * 0.002
      
      {max, min, PI} = Math
      @camera.pitch.rotation.x = max(-PI / 2, min(PI / 2, @camera.pitch.rotation.x))

module.exports = Controls