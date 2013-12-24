@getHeightFromColor = (color, heightScale, heightOffset) ->
  Math.ceil((color / 255) * heightScale) + heightOffset

mod = (num, m) ->
  ((num % m) + m) % m

@toPositionObj = (arr, w, h) ->
  x: mod arr[0], w
  y: arr[1]
  z: arr[2]
