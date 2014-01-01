module.exports = (hue) ->
  sky = 
    hours:
      0: {color: {h: hue, s: 0.3, l: 0}}
      450: {color: {h: hue, s: 0.3, l: 0.5}}
      600: {color: {h: hue, s: 0.3, l: 0.7}}
      1700: {color: {h: hue, s: 0.3, l: 0.5}}
      1850: {color: {h: hue, s: 0.3, l: 0}}

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

    sun: no
    stars: yes

  return (time) ->
    my = sky

    hour = Math.round(time / 50) * 50
    speed = Math.abs(my.last - time)

    game = @game

    timeout = (code, args, ms) -> 
      game.setTimeout(-> 
        code.apply this, args
      , ms || 100)

    prevHour = 0

    # run initialization once
    if my.init
      my.init.call this
      delete my.init
      # hours with a color defined
      my.allhours = (parseInt(k, 10) for k, v of my.hours)
      for h, i in my.allhours
        if hour < h and i > 0
          prevHour = my.allhours[i - 1]
          break
    
    # switch color based on time of day
    # maybe make this next part into a helper function
    if my.hours[hour]
      unless my.until
        @color my.hours[hour].color, (if speed > 9 then 100 else 1000)
        my.until = hour + 100
    my.until = false if my.until is hour

    if prevHour
      @color my.hours[prevHour].color, 1
    
    # fade stars in and out
    if my.last < 500 <= time or (my.stars and 500 <= prevHour < 1800)
      @paint ['top', 'left', 'right', 'front', 'back'], ->
        @material.transparent = true
        starsi = (mat) ->
          mat.opacity -= 0.1
          timeout(starsi, [mat]) if mat.opacity > 0
        if my.last < 500 <= time
          timeout starsi, [@material]
        else
          @material.opacity = 0

    if my.last < 1800 <= time
      @paint ['top', 'left', 'right', 'front', 'back'], ->
        @material.transparent = true
        starsi = (mat) ->
          mat.opacity += 0.1
          if mat.opacity < 1
            timeout(starsi, [mat])
        timeout starsi, [@material]
    
    # turn on sunlight
    if my.last < 500 <= time or (not my.sun and 500 <= prevHour < 1800)
      sunlight = @sunlight
      suni = ->
        sunlight.intensity += 0.1
        timeout(suni) if sunlight.intensity < 0.5
      if my.last < 500 <= time
        timeout(suni)
      else
        sunlight.intensity = 0.5
    
    # turn off sunlight
    if my.last < 1800 <= time
      sunlight = @sunlight
      suni = ->
        sunlight.intensity -= 0.1
        timeout(suni) if sunlight.intensity > 0
      timeout(suni)
    
    my.last = time

    # spin the sky 1 revolution per day
    @spin Math.PI * 2 * (time / 2400)
    
    # keep track of days
    my.day++  if time is 2400