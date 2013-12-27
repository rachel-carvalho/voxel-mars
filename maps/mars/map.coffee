module.exports =
  name: 'mars'
  
  # width and height of each img file
  width: 11520
  height: 5632

  # map scale info
  metersPerPixel: 463
  pixelsPerDegree: 128
  
  # which elevation is zero
  datum: 8208
  
  # difference between max and min elevation in map
  # 29457m:  highest point: olympus mons at 21249m, lowest: hellas planitia at -8208m
  deltaY: 29457

  # how original .img files are split (optional, defaults to 1x1: one file)
  cols: 4
  rows: 4

  # how latitude and longitude 0 are positioned in map
  latLngCenter:
    lat: 'center'
    lng: 'left'

  # how many voxels high the world will be
  # by default it's calculated (deltaY / metersPerPixel) to keep same scale
  # heightscale: 255

  renderOptions:
    # point of interest key where players start
    startPosition: 'biblisTholus'
    chunkSize: 32
    # how each img file is divided in zones (defaults to 1x1)
    zones:
      cols: 4
      rows: 2

  pointsOfInterest:
    # key to be referenced by renderOptions.startPosition
    olympusMons:
      name: 'Olympus Mons'
      lat: 17.34375
      lng: -133.453125

    vallesMarineris:
      name: 'Valles Marineris'
      lat: -13.5
      lng: -69.09375

    lowestPointInHellas:
      name: 'Lowest point in Hellas Basin'
      lat: -32.90625
      lng: 62.1953125

    biblisTholus:
      name: 'Biblis Tholus'
      lat: 1.890625
      lng: -123.7265625