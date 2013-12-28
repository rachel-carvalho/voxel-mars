@getHeightFromColor = (color, heightScale, heightOffset) ->
  Math.ceil((color / 255) * heightScale) + heightOffset
