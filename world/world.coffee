module.exports =
  name: 'mars'

  # map scale info
  metersPerPixel: 463
  pixelsPerDegree: 128

  # in pixels / voxels
  width: 46080
  height: 22528
  
  cols: 16 # 4 zones per .img
  rows: 8 # 2 zones per .img

  # origin of coordinates (lat 0, lng 0) in voxely coords
  origin: {x: 0, z: 22528 / 2}
  
  # which elevation (in meters) is zero
  datum: 8208
  
  # difference (in meters) between max and min elevation in map
  # highest point: olympus mons at 21249m, lowest: hellas planitia at -8208m
  heightSpan: 29457

  # how many voxels high the world will be
  # by default it's calculated (heightSpan / metersPerPixel) to keep same scale
  # heightScale: 128 # natural: 63.622030237580994

  # start: {lat: 87, lng: 1} # top left corner of image
  # start: {lat: 1.500625, lng: -123.7265625} # Biblis Tholus, closer to zone edge
  start: {lat: 1.890625, lng: -123.7265625} # Biblis Tholus
  # start: {lat: 17.34375, lng: -133.453125} # Olympus Mons
  # start: {lat: -13.5, lng: -69.09375} # Valle Marineris
  # start: {lat: -13.7890625, lng: -65.4218750} # Coprates
  # start: {lat: -15.8437500, lng: -63.6875000} # Reference crater
  # start: {lat: 1.8281250, lng: -122.6171875} # Reference crater 2
  # start: {lat: -32.90625, lng: 62.1953125} # Lowest point in Hellas