###
SUBLIME KEYS:
- alt + shift + s (syntax check)
- alt + shift + c (compile)
- alt + shift + w (watch)

TODO:
- increasing levels (easy)
- block sprites
- animation
###


$ = (sel) ->
  if typeof sel == 'string'
    document.querySelector sel
  else
    sel


class Canvas
  constructor: (@w, @h, @parent) ->
    unless @h? then @h = @w
    @el = document.createElement 'canvas'
    @el.setAttribute 'width',  @w
    @el.setAttribute 'height', @h
    if @parent then @parent.appendChild @el
    @ctx = @el.getContext '2d'
  
  clear: () ->
    @ctx.clearRect 0, 0, @w, @h


class Grid
  constructor: (@w, @h, arr, color) ->
    @_a = new Array(@w * @h)
    @setArray(arr) if arr?
    @color = color if color?

  get: (x, y) -> @_a[@w*y + x]

  set: (x, y, v=true) -> @_a[@w*y + x] = v

  unset: (x, y) -> @set(x, y, false)

  setArray: (arr) -> @set(p[0], p[1]) for p in arr

  rotatedClone: () ->
      n = new Grid(@h, @w)
      for y in [0 ... @h]
        for x in [0 ... @w]
          n.set @h - y - 1, x, !!@get(x, y)
      n.color = @color if @color?
      n

  r: () -> @rotatedClone()

  collides: (n, pos) ->
    # test 4 limits
    if pos[0] < 0 or
       pos[1] < 0 or
       pos[0] + n.w > @w or
       pos[1] + n.h > @h
          return true
        
    # stop at first collision
    for y in [0 ... n.h]
      for x in [0 ... n.w]
        if n.get(x, y) and @get(x + pos[0], y + pos[1]) then return true
    false

  put: (n, pos) ->
    hasColor = n.color?
    for y in [0 ... n.h]
      for x in [0 ... n.w]
        v = n.get x, y
        if v
          v = n.color if hasColor
          @set x + pos[0], y + pos[1], v

  isLineFilled: (y) ->
    for x in [0 ... @w]
      return false unless @get x, y
    true

  eraseLine: (y) ->
    for x in [0 ... @w]
      @unset x, y
    false

  copyLineAbove: (y) ->
    for x in [0 ... @w]
      v = @get x, y - 1
      if v
        @set x, y, v
      else
        @unset x, y

  gravity: (y0) ->
    for y in [y0 ... 0]
      @copyLineAbove y
    @eraseLine 0
    
  toString: () ->
    r = []
    for y in [0 ... @h]
      for x in [0 ... @w]
        if @get x, y
          r.push('O')
        else
          r.push('.')
      r.push '\n'
    r.join('')
   
        
# http://en.wikipedia.org/wiki/Tetris#Gameplay
blocks = [
  new Grid 4,1, [ [0,0], [1,0], [2,0], [3,0] ], '#F00' # ---  red
  new Grid 3,2, [ [0,0], [0,1], [1,1], [2,1] ], '#FF0' # L_   yellow
  new Grid 3,2, [ [2,0], [0,1], [1,1], [2,1] ], '#F0F' # _J   magenta
  new Grid 2,2, [ [0,0], [1,0], [0,1], [1,1] ], '#00F' # []   blue
  new Grid 3,2, [ [1,0], [2,0], [0,1], [1,1] ], '#0FF' # _-   cyan
  new Grid 3,2, [ [1,0], [0,1], [1,1], [2,1] ], '#0F0' # _!_  green
  new Grid 3,2, [ [0,0], [1,0], [1,1], [2,1] ], '#F70' # -_   orange
]
  
# rotated blocks computed upfront...
blocks2 = []
for b in blocks
  row = []
  for i in [0 .. 3]
    row.push b
    b = b.r()
  blocks2.push row
  

window.Tetris =
  
  init: (o) ->
    @_containerEl = document.body
    @_cellSize    = 16

    @_containerEl = $(o.container) if o.container?
    @_cellSize    =   o.cellSize   if o.cellSize?
    @_scoreEl     = $(o.score)     if o.score?
    @_nextEl      = $(o.next)      if o.next?

    @restartGame()
  
    # set up canvases
    @_mainCvs = new Canvas @state.grid.w * @_cellSize, @state.grid.h * @_cellSize, @_containerEl
    @_mainCtx = @_mainCvs.ctx

    @_nextPieceCvs = new Canvas 4 * @_cellSize, 4 * @_cellSize, @_nextEl
    @_nextPieceCtx = @_nextPieceCvs.ctx

    @draw()


  restartGame: () ->
    @state =
      score: 0
      lines: 0
      level: 0
      grid:  new Grid 10, 16
      piece:
        idx: Math.floor( Math.random() * 7 )
        rot: 0
        pos: [4, 0]
      nextPiece:
        idx: Math.floor( Math.random() * 7 )
        rot: 0
        pos: [0, 0]

    @updatePiece()
    @updatePiece(true)
    @increaseScore()

    @timer = setInterval @down.bind(@), 300
    

  updatePiece: (next) ->
    p = if next then @state.nextPiece else @state.piece
    p.grid = blocks2[ p.idx ][ p.rot ]
    if next
      p.pos = [
        (4 - p.grid.w) / 2,
        (4 - p.grid.h) / 2
      ]
    

  increaseScore: (nrLines=0) ->
    s = @state
    inc = switch nrLines
      when 0 then    0
      when 1 then   40
      when 2 then  100
      when 1 then  300
      when 2 then 1200
    s.lines += nrLines
    s.score += inc * (s.level + 1)
    @updateScore [
      "<p><b>score</b>: #{s.score}</p>",
      "<p><b>lines</b>: #{s.lines}</p>",
      "<p><b>level</b>: #{s.level}</p>",
    ].join ''


  updateScore: (msg) ->
    @_scoreEl.innerHTML = msg
      

  draw: () ->
    s  = @state
    p  = s.piece
    np = s.nextPiece

    @_mainCvs.clear()
    @drawGrid s.grid, @_mainCtx
    @drawGrid p.grid, @_mainCtx, p.pos unless @skipPieceDraw

    @_nextPieceCvs.clear()
    @drawGrid np.grid, @_nextPieceCtx, np.pos
    return
      
      
  drawGrid: (g, ctx, dlt=[0,0]) ->
    gridHasColor = g.color?
    ctx.fillStyle = g.color if gridHasColor
    cs = @_cellSize
    for y in [0 ... g.h]
      for x in [0 ... g.w]
        v = g.get x, y
        if v
          ctx.fillStyle = v unless gridHasColor
          ctx.fillRect (dlt[0]+x)*cs, (dlt[1]+y)*cs, cs, cs
    return


  isColliding: () ->
    @state.grid.collides @state.piece.grid, @state.piece.pos


  endGame: () ->
    clearInterval @timer
    delete @timer
    @updateScore 'game over'
    true


  correctCollision: (x=0, y=0) ->
    unless @isColliding() then return false
    if y > 0
      @state.piece.pos[1] -= 1
      if @isColliding() then return @endGame()
      @gluePiece()
    else if x in [-1, 1]
      @state.piece.pos[0] -= x
    else
      @state.piece.pos[0] += 1
      if @isColliding()
        @state.piece.pos[0] -= 2
        if @isColliding() then return @endGame()
      return false
    true


  gluePiece: () ->
    g = @state.grid
    p = @state.piece
    np = @state.nextPiece
    pos = p.pos

    g.put p.grid, pos

    nrLines = 0
    dy = p.grid.h - 1
    while dy >= 0
      y = pos[1] + dy
      isF = g.isLineFilled y
      if isF
        nrLines += 1
        g.gravity y
      else
        dy -= 1
    
    @increaseScore nrLines if nrLines > 0

    # next piece
    p.idx = np.idx
    p.rot = 0
    p.pos = [4, 0]
    np.idx = Math.floor( Math.random() * 7 )

    @updatePiece()
    @updatePiece(true)

    @draw()


  isRunning: () ->
    !!@timer


  left: () ->
    @state.piece.pos[0] -= 1
    @correctCollision(-1)
    @draw()
    

  right: () ->
    @state.piece.pos[0] += 1
    @correctCollision(1)
    @draw()
    

  rotR: () ->
    p = @state.piece
    if p.rot > 0 then p.rot -= 1 else p.rot = 3
    if p.idx == 0 then p.pos[0] += (p.rot % 2 - 0.5) * 2
    @updatePiece()
    @correctCollision()
    @draw()
    

  rotL: () ->
    p = @state.piece
    if p.rot < 3 then p.rot += 1 else p.rot = 0
    if p.idx == 0 then p.pos[0] += (p.rot % 2 - 0.5) * 2
    @updatePiece()
    @correctCollision()
    @draw()
    

  down: () ->
    @state.piece.pos[1] += 1
    @correctCollision(0, 1)
    @draw()


  downAll: () ->
    while not @correctCollision(0, 1)
      @state.piece.pos[1] += 1


  togglePause: () ->
    if @timer
      clearInterval @timer
      delete @timer
      @updateScore 'game is paused'
    else
      @timer = setInterval @down.bind(@), 300
      @increaseScore 0
  

# GO GO GO
t = window.Tetris
t.init
  container: '#grid'
  score:     '#score'
  next:      '#next'
  cellSize:  20


document.addEventListener 'keydown', (ev) ->
  # l:37, r:39, u:38, d:40, z:90, x:88, p:80
  console.log ev.keyCode
  switch ev.keyCode
    when 37     then t.left()        if t.isRunning()
    when 39     then t.right()       if t.isRunning()
    when 38, 88 then t.rotL()        if t.isRunning()
    when 90     then t.rotR()        if t.isRunning()
    when 40     then t.down()        if t.isRunning()
    when 32     then t.downAll()     if t.isRunning()
    when 80     then t.togglePause()

