###
SUBLIME KEYS:
- alt + shift + s (syntax check)
- alt + shift + c (compile)
- alt + shift + w (watch)

TODO:
- grids collisions test
- collide and move down
- block sprites
- animation
###


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
    if (pos[0] < 0 or pos[1] < 0 or pos[0] + n.w > @w or pos[1] + n.h > @h) then return true
        
    # stop at first collision
    for y in [0 ... n.h]
      for x in [0 ... n.w]
        if (n.get x, y and @get x + pos[0], y + pos[1]) then return true
    false

  put: (n, pos) ->
    hasColor = n.color?
    for y in [0 ... n.h]
      for x in [0 ... n.w]
        v = n.get x, y
        if (v)
          v = n.color if hasColor
          @.set x + pos[0], y + pos[1], v

  eraseLine: (y) ->
    for x in [0 ... @w] then @unset x, y

  gravity: (y) ->
    for y in [y .. 1]
      for x in [0 ... @w]
        @set x, y @get(x, y - 1)
    @eraseLine 0

        
        
# http://en.wikipedia.org/wiki/Tetris#Gameplay
blocks = [
  new Grid 4,1, [ [0,0], [1,0], [2,0], [3,0] ], '#700' # ---
  new Grid 3,2, [ [0,0], [0,1], [1,1], [2,1] ], '#070' # L_
  new Grid 3,2, [ [2,0], [0,1], [1,1], [2,1] ], '#007' # _J
  new Grid 2,2, [ [0,0], [1,0], [0,1], [1,1] ], '#770' # []
  new Grid 3,2, [ [1,0], [2,0], [0,1], [1,1] ], '#077' # _-
  new Grid 3,2, [ [1,0], [0,1], [1,1], [2,1] ], '#707' # _!_
  new Grid 3,2, [ [0,0], [1,0], [1,1], [2,1] ], '#444' # -_
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
  
  init: (@containerEl=document.body, @cellSize=12) ->
    @state =
      score: 0
      grid: new Grid 10, 16
      piece:
        idx: 1
        rot: 0
        pos: [0, 0]
      
    

    # set up canvas
    @_cvsEl = document.createElement 'canvas'
    @_cvsW = @state.grid.w * @cellSize
    @_cvsH = @state.grid.h * @cellSize
    @_cvsEl.setAttribute 'width',  @_cvsW
    @_cvsEl.setAttribute 'height', @_cvsH
    @containerEl.appendChild @_cvsEl
    @ctx = @_cvsEl.getContext '2d'

    @updatePiece()
    @draw()



  updatePiece: () ->
    p = @state.piece
    @state.piece.grid = blocks2[ p.idx ][ p.rot ]
      
      
      
  draw: () ->
    s = @state
    p = s.piece

    @ctx.clearRect 0, 0, @_cvsW, @_cvsH

    #g.put b, p.pos
    #@drawGrid g, @ctx #, [0, 1]
    
    @drawGrid p.grid, @ctx, p.pos
    return
      
      
      
  drawGrid: (g, ctx, dlt=[0,0]) ->
    gridHasColor = g.color?
    ctx.fillStyle = g.color if gridHasColor
    cs = @cellSize
    for y in [0 ... g.h]
      for x in [0 ... g.w]
        v = g.get x, y
        if v
          ctx.fillStyle = v unless gridHasColor
          ctx.fillRect (dlt[0]+x)*cs, (dlt[1]+y)*cs, cs, cs
    return
      

   
  left: () ->
    p = @state.piece.pos
    p[0] -= 1 if p[0] > 0
    @draw()
    
  right: () ->
    p = @state.piece.pos
    p[0] += 1 if p[0] < @state.grid.w - @state.piece.grid.w
    @draw()
    
  rotR: () ->
    p = @state.piece
    if p.rot > 0 then p.rot -= 1 else p.rot = 3
    @updatePiece()
    @draw()
    
  rotL: () ->
    p = @state.piece
    if p.rot < 3 then p.rot += 1 else p.rot = 0
    @updatePiece()
    @draw()
    
  down: () ->
  downAll: () ->

  
  
# GO GO GO
t = window.Tetris
t.init()

document.addEventListener 'keydown', (ev) ->
  # l:37, r:39, u:38, d:40, z:90, x:88
  switch ev.keyCode
    when 37     then t.left()
    when 39     then t.right()
    when 38, 88 then t.rotR()
    when 90     then t.rotL()
    when 40     then t.down()
    when 32     then t.downAll()
