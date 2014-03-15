loadImage = (path, callback) ->
  img = new Image()
  img.onload = -> callback(img)
  img.src = path
  
  img

module.exports = {loadImage}