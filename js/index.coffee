window.log = log = -> console.log.apply console, arguments

$ = require './browser/yocto.coffee'
THREE = require './three/three-r65.js'
Stats = require './three/stats-r11.js'
RendererStats = require './three/renderer-stats.js'

Clock = require './clock.coffee'
World = require './world.coffee'
Light = require './light.coffee'
Controls = require './controls.coffee'
Physics = require './physics.coffee'

Welcome = require './welcome.coffee'
InfoPanel = require './info-panel.coffee'
NavMaps = require './nav-maps.coffee'

class Game
  constructor: ->
    @container = $("#world")
    @welcome = new Welcome(this)

    @world = new World this,
      firstZoneCreated: =>
        @clock = new Clock(this)

        @scene = @createScene()

        @renderer = @createRenderer(@container)

        @light = new Light(@scene, @renderer, @clock)

        @avatar = @createAvatar()

        @camera = @createCamera(@scene, @avatar)

        @headLamp = @createHeadLamp(@scene, @camera)

        @controls = new Controls(this, @container, @camera)
        
        @physics = @createPhysics(@avatar, @camera, @controls)

        @stats = @createStats(@container)
        @rendererStats = @createRendererStats(@container)

        window.addEventListener 'resize', @resize

        @infoPanel = new InfoPanel(@clock, @world)
        @navMaps = new NavMaps(@world)

        @step()

      firstTodo: (count) => @welcome.setProgressMax(count)
      chunkCreated: => @welcome.advanceProgress()

  createScene: ->
    scene = new THREE.Scene()

    scene.fog = new THREE.FogExp2(0xf2c8b8, 0.00020)

    scene.ambientLight = al = new THREE.AmbientLight(0xcccccc)
    scene.add al

    scene.directionalLight = dl = new THREE.DirectionalLight(0xffffff, 1.5)
    dl.position.set(1, 1, -0.5).normalize()
    scene.add dl
    
    scene

  createRenderer: (container) ->
    {innerWidth, innerHeight} = window

    renderer = new THREE.WebGLRenderer(antialias: no, precision: 'lowp')
    renderer.setClearColor 0xf2c8b8
    renderer.setSize innerWidth, innerHeight

    container.el.appendChild renderer.domElement
    
    renderer

  createAvatar: ->
    {voxelSize} = @world

    width = voxelSize / 2
    height = voxelSize * 1.7

    g = new THREE.CubeGeometry width, height, width

    mat = new THREE.MeshLambertMaterial color: 0x0000cc

    avatar = new THREE.Mesh g, mat
    y = height / 2
    avatar.position.setY y

    avatar

  createCamera: (scene, avatar) ->
    {innerWidth, innerHeight} = window
    {voxelSize} = @world
    
    camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 1, 20000)

    camera.rotation.set 0, 0, 0

    camera.pitch = new THREE.Object3D()
    camera.pitch.add camera
    camera.pitch.position.setY voxelSize * 1.5

    camera.yaw = new THREE.Object3D()
    camera.yaw.add camera.pitch
    camera.yaw.add avatar

    threely = @world.latLng(@world.start).toThreely()
    voxely = threely.toVoxely()

    camera.yaw.position.set threely.x, @world.getAvatarY(voxely.x, voxely.z), threely.z

    scene.add camera.yaw
    
    camera

  createHeadLamp: (scene, camera) ->
    scene.headLamp = new THREE.SpotLight 0xffffff, 2
    scene.headLamp.distance = @world.voxelSize * 20
    scene.headLamp.position.z = @world.voxelSize
    scene.headLamp.target.position.z = -(@world.voxelSize / 10)

    camera.pitch.add scene.headLamp.target
    camera.pitch.add scene.headLamp

    @scene.headLamp

  createPhysics: (avatar, camera, controls) ->
    physics = new Physics {
      avatar, camera, controls
      threelyToVoxely: (c) => @world.threely(c).toVoxely()
      getAvatarY: (x, z) => @world.getAvatarY(x, z)
    }
      
    physics

  createStats: (container) ->
    stats = new Stats()
    stats.domElement.style.position = 'absolute'
    stats.domElement.style.bottom = '0px'
    stats.domElement.classList.add 'debug'
    container.el.appendChild stats.domElement
    
    stats

  createRendererStats: (container) ->
    rendererStats = new RendererStats()
    rendererStats.domElement.style.position = 'absolute'
    rendererStats.domElement.style.top = '0px'
    rendererStats.domElement.classList.add 'debug'
    container.el.appendChild(rendererStats.domElement)

    rendererStats

  toggleDebug: ->
    if @debug then $('.debug').hide() else $('.debug').show()
    @debug = not @debug

  resize: =>
    {innerWidth, innerHeight} = window

    @camera.aspect = innerWidth / innerHeight
    @camera.updateProjectionMatrix()
    @renderer.setSize innerWidth, innerHeight

  step: =>
    if @debug
      @stats.update()
      @rendererStats.update(@renderer)

    @world.update(@camera.yaw.position)
    @physics.update(@clock.getDelta()) if @controls.pointerLock.locked()
    @renderer.render(@scene, @camera)
    @light.update(@clock)

    @infoPanel.update(@camera.yaw.position)
    @navMaps.update(@camera.yaw.position)

    window.requestAnimationFrame @step

window.game = new Game()