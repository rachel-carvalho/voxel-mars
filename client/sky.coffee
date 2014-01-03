module.exports = (hue) ->
  sky = 
    hue: hue
    sat: 0.3

    sunrise: 500
    sunset: 1800

    fullLight: 0.5

    getColorObject: (lum) ->
      color: h: @hue, s: @sat, l: lum

    createHours: () ->
      @hours = {}

      @hours[0] = sky.getColorObject 0
      @hours[sky.sunrise - 50] = sky.getColorObject 0.5
      @hours[sky.sunrise + 100] = sky.getColorObject 0.7
      @hours[sky.sunset - 100] = sky.getColorObject 0.5
      @hours[sky.sunset + 50] = sky.getColorObject 0

    init: (sky) ->
      # build sky colors per hour object
      sky.createHours()

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
      my.init.call this, my
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
    if my.last < sky.sunrise <= time or (my.stars and sky.sunrise <= prevHour < sky.sunset)
      @paint ['top', 'left', 'right', 'front', 'back'], ->
        @material.transparent = true
        starsi = (mat) ->
          mat.opacity -= 0.1
          timeout(starsi, [mat]) if mat.opacity > 0
        if my.last < sky.sunrise <= time
          timeout starsi, [@material]
        else
          @material.opacity = 0

    if my.last < sky.sunset <= time
      @paint ['top', 'left', 'right', 'front', 'back'], ->
        @material.transparent = true
        starsi = (mat) ->
          mat.opacity += 0.1
          if mat.opacity < 1
            timeout(starsi, [mat])
        timeout starsi, [@material]
    
    # turn on sunlight
    if my.last < sky.sunrise <= time or (not my.sun and sky.sunrise <= prevHour < sky.sunset)
      sunlight = @sunlight
      suni = ->
        sunlight.intensity += 0.1
        timeout(suni) if sunlight.intensity < sky.fullLight
      if my.last < sky.sunrise <= time
        timeout(suni)
      else
        sunlight.intensity = sky.fullLight
    
    # turn off sunlight
    if my.last < sky.sunset <= time
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