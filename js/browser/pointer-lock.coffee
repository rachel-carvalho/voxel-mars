class PointerLock
  element: null
  prefix: ''
  capable: no

  constructor: (@element) ->
    requestPointerLock = @element.requestPointerLock

    unless @element.requestPointerLock
      for vendor in ['moz', 'webkit', 'o', 'ms']
        @prefix = vendor if @element["#{vendor}RequestPointerLock"]
        requestPointerLock = requestPointerLock || @element["#{vendor}RequestPointerLock"]

    @capable = !!requestPointerLock

  getPrefixedMethod: (method) =>
    prefixed = "#{@prefix}#{method}"
    prefixed[0].toLowerCase() + prefixed[1..-1]

  locked: =>
    @capable && @element is @getElement()

  request: =>
    @capable && @element[@getPrefixedMethod('RequestPointerLock')]()

  exit: =>
    @capable && document[@getPrefixedMethod('ExitPointerLock')]()

  getElement: =>
    @capable && document[@getPrefixedMethod('PointerLockElement')]

  getMovement: (e) =>
    x: e[@getPrefixedMethod('MovementX')] or 0
    y: e[@getPrefixedMethod('MovementY')] or 0

  on: (handlers) ->
    document.addEventListener "#{@prefix}pointerlockchange", handlers.change

module.exports = PointerLock
