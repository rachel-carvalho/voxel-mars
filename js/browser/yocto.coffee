# sub-zepto jQuery replacement

$ = (input) ->
  if typeof input is 'object' then new Element(input)
  else if input.match(/^#\S+$/) then new Element(document.getElementById input.slice(1))
  else new Collection(document.querySelectorAll input)

class Element
  constructor: (@el) ->
  html: (input) -> if not input? then @el.innerHTML; else @el.innerHTML = input; this
  attr: (input) ->
    if typeof input is 'string' then @el[input]
    else @el[k] = v for k, v of input; this
  val: (input) -> if not input? then @attr 'value'; else @attr value: input; this
  css: (props) ->
    for k, v of props
      v += 'px' if typeof v is 'number'
      @el.style[k] = v
    this
  width: (input) -> if not input? then @el.clientWidth; else @el.clientWidth = input; this
  height: (input) -> if not input? then @el.clientHeight; else @el.clientHeight = input; this
  hide: ->
    @oldDisplay = @el.style.display unless @el.style.display is 'none'
    @el.style.display = 'none'
    this
  show: -> @el.style.display = @oldDisplay ? 'block'; this
  toggle: ->
    if not @el.style.display? or @el.style.display in ['', 'none'] then @show()
    else @hide()
  on: (obj) -> @el.addEventListener ev, cb for ev, cb of obj; this
  click: (cb) -> @on click: cb

class Collection extends Array
  constructor: (els) -> @push(new Element(el)) for el, i in els
  first: -> this[0]
  html: (input) ->
    if not input? then this[0].html()
    else el.html(input) for el in this; this
  attr: (input) ->
    if typeof input is 'string' then this[0].attr(input)
    else el.attr(input) for el in this; this
  val: (input) ->
    if not input? then this[0].val()
    else el.val(input) for el in this; this
  css: (props) -> el.css(props) for el in this; this
  width: (input) ->
    if not input? then this[0].width()
    else el.width(input) for el in this; this
  height: (input) ->
    if not input? then this[0].height()
    else el.height(input) for el in this; this
  hide: -> el.hide() for el in this; this
  show: -> el.show() for el in this; this
  toggle: -> el.toggle() for el in this; this
  on: (obj) -> el.on(obj) for el in this; this
  click: (cb) -> el.click(cb) for el in this; this

module.exports = $
