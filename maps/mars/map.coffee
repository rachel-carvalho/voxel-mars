module.exports =
  name: 'mars'
  width: 11520
  height: 5632
  metersPerPixel: 463
  pixelsPerDegree: 128
  datum: 8208
  deltaY: 29457
  cols: 4
  rows: 4

  renderOptions:
    startPosition: 'biblisTholus'
    chunkSize: 32
    zones:
      cols: 4
      rows: 2

  pointsOfInterest:
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