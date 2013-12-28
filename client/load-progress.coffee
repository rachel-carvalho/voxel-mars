class LoadProgress
  constructor: (opts) ->
    {chunkDistance, mapImg, @onUpdate, @onComplete} = opts

    @chunkProgress =
      value: 0
      max: Math.pow chunkDistance * 2, 3

    imgProgress = 
      max: Math.floor @chunkProgress.max / 4
    
    @chunkProgress.max += imgProgress.max

    mapImg.one 'load', =>
      @update imgProgress.max

    @update 0


  update: (val = 1) ->
    if @chunkProgress.value < @chunkProgress.max
      @chunkProgress.value += val

      @onUpdate @chunkProgress
      
      if @chunkProgress.value is @chunkProgress.max
        @onComplete @chunkProgress


module.exports = LoadProgress