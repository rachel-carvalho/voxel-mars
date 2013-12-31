sky =
  hours:
    0: {color: {h: 26/360, s: 0.3, l: 0}}
    450: {color: {h: 26/360, s: 0.3, l: 0.5}}
    600: {color: {h: 26/360, s: 0.3, l: 0.7}}
    1700: {color: {h: 26/360, s: 0.3, l: 0.5}}
    1850: {color: {h: 26/360, s: 0.3, l: 0}}
  
  init: ->
    # add a sun on the bottom
    @paint('bottom', @sun, 15)
    # add some stars
    @paint(['top', 'left', 'right', 'front', 'back'], @stars, 500)
    # no sunlight at startup
    @sunlight.intensity = 0

  day: 0
  until: no
  last: 0

module.exports = (time) ->
  my = sky
  hour = Math.round(time / 50) * 50
  speed = Math.abs(my.last - time)
  my.last = time

  game = @game

  timeout = (code, ms) -> game.setTimeout code, ms || 100

  # run initialization once
  if my.init
    my.init.call this
    delete my.init
  
  # switch color based on time of day
  # maybe make this next part into a helper function
  if my.hours[hour]
    unless my.until
      @color my.hours[hour].color, (if speed > 9 then 100 else 1000)
      my.until = hour + 100
  my.until = false if my.until is hour
  
  # fade stars in and out
  if time is 500
    @paint ['top', 'left', 'right', 'front', 'back'], ->
      @material.transparent = true
      mat = @material
      i = ->
        mat.opacity -= 0.1
        timeout(i) if mat.opacity > 0
      timeout(i)

  if time is 1800
    @paint ['top', 'left', 'right', 'front', 'back'], ->
      @material.transparent = true
      mat = @material
      i = ->
        mat.opacity += 0.1
        timeout(i) if mat.opacity < 1
      timeout(i)
  
  # turn on sunlight
  if time is 500
    sunlight = @sunlight
    log sunlight.intensity
    i = ->
      sunlight.intensity += 0.1
      timeout(i) if sunlight.intensity < 0.5
    timeout(i)
  
  # turn off sunlight
  if time is 1800
    sunlight = @sunlight
    i = ->
      sunlight.intensity -= 0.1
      timeout(i) if sunlight.intensity > 0
    timeout(i)
  
  # spin the sky 1 revolution per day
  @spin Math.PI * 2 * (time / 2400)
  
  # keep track of days
  my.day++  if time is 2400