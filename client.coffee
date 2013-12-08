window.log = -> console.log.apply console, arguments

voxel = require 'voxel'
vengine = require 'voxel-engine'
vplayer = require 'voxel-player'
vwalk = require 'voxel-walk'

{map} = app

get = (url, cb) ->
  xhr = new XMLHttpRequest()
  xhr.open 'GET', url
  xhr.send()
  xhr.onload = -> cb(JSON.parse @responseText)

chunkSize = 32

game = app.game = vengine
  materials: ['height5']
  materialFlatColor: no
  generateChunks: no
  chunkSize: chunkSize
  chunkDistance: 2
  worldOrigin: [0, 0, 0]
  controls: {discreteFire: true}
  skyColor: 0xFA8072

game.appendTo(document.body)

avatar = vplayer(game)('astronaut.png')
avatar.possess()
avatar.position.set(0, 32, 0)
avatar.toggle()

target = game.controls.target()

game.on 'tick', ->
  vwalk.render(target.playerSkin)
  vx = Math.abs(target.velocity.x)
  vz = Math.abs(target.velocity.z)
  if vx > 0.001 or vz > 0.001 then vwalk.stopWalking()
  else vwalk.startWalking()

div = document.querySelector('#mid-map')
pointer = document.querySelector('#pointer')
img = document.querySelector('#mid-map img')

window.addEventListener 'keydown', (ev) ->
  if ev.keyCode is 'M'.charCodeAt(0)
    pos = target.position
    
    if div.style.display isnt 'block' then div.style.display = 'block'
    
    if div.style.zIndex is '-9999' then div.style.zIndex = '9999'
    else div.style.zIndex = '-9999' 

    pointer.style.top = "#{((map.center.y + Math.floor pos.z) / map.height) * img.height}px"
    pointer.style.left = "#{((map.center.x + Math.floor pos.x) / map.width) * img.width}px"

game.voxels.on 'missingChunk', (chunkPosition) ->
  get "/map/#{chunkPosition[0]}/#{chunkPosition[2]}.json", (heightmap) ->

    game.showChunk
      position: chunkPosition
      dims: [chunkSize, chunkSize, chunkSize]
      voxels: terrainGenerator(heightmap, chunkPosition, chunkSize)

terrainGenerator = (map, position, w) ->
  chunk = new Int8Array(w * w * w)

  startX = 0 #position[0] * w
  startY = 0 #position[1] * w
  startZ = 0 #position[2] * w

  if position[1] is 0
    for x in [startX...(startX + w)]
      for z in [startZ...(startZ + w)]
        height = Math.ceil (map[Math.abs z][Math.abs x] / 255) * 32

        for h in [0..height]
          xidx = Math.abs((w + x % w) % w)
          yidx = Math.abs((w + h % w) % w)
          zidx = Math.abs((w + z % w) % w)
      
          idx = xidx + yidx * w + zidx * w * w
          chunk[idx] = 1

  chunk
