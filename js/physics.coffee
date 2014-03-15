THREE = require './three/three-r65.js'

class Physics
  constructor: (params) ->
    {@avatar, @camera, @controls, @getAvatarY, @threelyToVoxely} = params
    
    @canJump = no

    @velocity = new THREE.Vector3()

    @walkSpeed = 0.6
    @jumpHeight = 8
    @maxWalkSpeed = @walkSpeed * 5
    @walkDeceleration = 0.08
    @maxDeceleration = @walkDeceleration * 5

  getRotatedVelocity: ->
    v = @velocity.clone()
    v.applyQuaternion @camera.yaw.quaternion
    v

  setRotatedVelocity: (rotatedVelocity) ->
    v = rotatedVelocity.clone()
    v.applyQuaternion @camera.yaw.quaternion.clone().inverse()
    @velocity.set v.x, v.y, v.z

  getBounds2D: (mesh, vel) ->
    w = mesh.geometry.width
    d = mesh.geometry.depth
    
    bounds = []

    for x in [0, 1]
      for z in [0, 1]
        point = @camera.yaw.position.clone().add(mesh.position).add(new THREE.Vector3(w * (x + 0.5), 0, d * (z + 0.5)))
        point.add vel if vel
        voxely = @threelyToVoxely(point)
        bounds.push
          threely: point
          voxely: voxely
          height: @getAvatarY(voxely.x, voxely.z)

    bounds

  getHighestFloor: (bounds) ->
    floor = 0

    for b in bounds
      floor = Math.max floor, b.height

    floor

  predictPositions: (v, floor) ->
    p = @camera.yaw.position.clone()
    p.add v
    newVoxelsP = @getBounds2D(@avatar, v)
    newFloor = @getHighestFloor(newVoxelsP)
    newFloorIsHigherAndPositionIsntEnough = newFloor > floor and p.y < newFloor

    {newVoxelsP, newFloor, newFloorIsHigherAndPositionIsntEnough, p}

  avoidCollisions: (rotatedVelocity, floor, voxelsP, avoided) ->
    originalVelocity = rotatedVelocity.clone()

    # new voxel and floor
    {newVoxelsP, newFloor, newFloorIsHigherAndPositionIsntEnough, p} = @predictPositions rotatedVelocity, floor
    
    resetVelocity =
      x: false
      z: false

    # for each axis,
    for axis in ['x', 'z']

      # new y is higher than previous floor and player hasn't jumped enough
      if newFloorIsHigherAndPositionIsntEnough

        # looks for voxel change
        for i in [0...voxelsP.length]
          voxelP = voxelsP[i]
          newVoxelP = newVoxelsP[i]
          originalVoxely = voxelP.voxely
          newVoxely = newVoxelP.voxely

          # if has changed voxel in any bounds and new voxel is higher 
          if originalVoxely[axis] isnt newVoxely[axis] and newVoxelP.height > voxelP.height
            other = if axis is 'x' then 'z' else 'x'

            # if other axis is already reset
            if resetVelocity[other]
              # undo and try resetting only this one
              resetVelocity[other] = false
              rotatedVelocity[other] = originalVelocity[other]

            # stop velocity and breaks bound loop for current axis
            rotatedVelocity[axis] = 0
            resetVelocity[axis] = true
            break
        
      # re-run predictions after each axis
      {newVoxelsP, newFloor, newFloorIsHigherAndPositionIsntEnough, p} = @predictPositions rotatedVelocity, floor

    # if only one axis still was not enough, reset both
    if newFloorIsHigherAndPositionIsntEnough
      rotatedVelocity.x = 0
      rotatedVelocity.z = 0
      {newVoxelsP, newFloor, newFloorIsHigherAndPositionIsntEnough, p} = @predictPositions rotatedVelocity, floor

    if p.y < newFloor
      rotatedVelocity.y = 0
      @camera.yaw.position.y = newFloor
      @canJump = true

  update: (delta) ->
    delta *= 100

    deceleration = Math.min(@walkDeceleration * delta, @maxDeceleration)
    
    @velocity.x += (-@velocity.x) * deceleration
    @velocity.z += (-@velocity.z) * deceleration
    
    @velocity.y -= 0.08 * delta
    
    if @controls.jumping()
      @velocity.y += @jumpHeight if @canJump
      @canJump = no
    
    speed = Math.min(@walkSpeed * delta, @maxWalkSpeed)
    
    @velocity.z -= speed if @controls.movingForward()
    @velocity.z += speed if @controls.movingBackward()
    @velocity.x -= speed if @controls.movingLeft()
    @velocity.x += speed if @controls.movingRight()
    
    rotatedVelocity = @getRotatedVelocity()
    
    voxelsP = @getBounds2D(@avatar)
    
    @avoidCollisions rotatedVelocity, @getHighestFloor(voxelsP), voxelsP, false
    
    @setRotatedVelocity rotatedVelocity
    @camera.yaw.position.add rotatedVelocity

module.exports = Physics