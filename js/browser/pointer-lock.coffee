class PointerLock
  constructor: (@element) ->
    if @element.requestPointerLock then @prefix = ''
    else
      for vendor in ['moz', 'webkit', 'o', 'ms']
        @prefix = vendor if @element["#{vendor}RequestPointerLock"]
        
    if not @prefix then @capable = no
    else
      @capable = yes
      @locked = => @element is @getElement()

      if @prefix is ''
        @request = => @element.requestPointerLock()
        @exit = => document.exitPointerLock()
        @getElement = -> document.pointerLockElement
        @getMovement = (e) => x: e.movementX or 0, y: e.movementY or 0
      else
        @request = => @element["#{@prefix}RequestPointerLock"]()
        @exit = => document["#{@prefix}ExitPointerLock"]()
        @getElement = => document["#{@prefix}PointerLockElement"]
        @getMovement = (e) =>
          x: e["#{@prefix}MovementX"] or 0
          y: e["#{@prefix}MovementY"] or 0
      
  on: (handlers) ->
    document.addEventListener "#{@prefix}pointerlockchange", handlers.change

module.exports = PointerLock