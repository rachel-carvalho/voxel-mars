module.exports =
  getHeightFromColor: (color, heightScale, heightOffset) ->
    Math.ceil((color / 255) * heightScale) + heightOffset

  toPositionObj: (arr) ->
    {x: arr[0], y: arr[1], z: arr[2]}
