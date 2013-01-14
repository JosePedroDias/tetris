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
    @a = new Array(@w * @h)
    @S(arr) if arr?
    @color = color if color?

  g: (x, y) -> @a[@w*y + x]                # get

  s: (x, y, v=true) -> @a[@w*y + x] = v    # set

  u: (x, y) -> @s(x, y, undefined)         # unset

  S: (arr) -> @s(p[0], p[1]) for p in arr  # set array

  r: () ->                                 # returns rotated clone
      n = new Grid(@h, @w)
      for y in [0 ... @h]
        for x in [0 ... @w]
          n.s @h - y - 1, x, !!@g(x, y)
      n.color = @color if @color?
      n

  c: (n, pos) -> # collides
    # test 4 limits
    if (pos[0] < 0 or pos[1] < 0 or pos[0] + n.w > @w or pos[1] + n.h > @h)
      return true
        
    # stop at first collision
    for y in [0 ... n.h]
      for x in [0 ... n.w]
        if (n.g x, y and @g x + pos[0], y + pos[1])
          return true
    return false

  p: (n, pos) -> # put
    hasColor = n.color?
    for y in [0 ... n.h]
      for x in [0 ... n.w]
        v = n.g x, y
        if (v)
          v = n.color if hasColor
          @.s x + pos[0], y + pos[1], v

  eraseLine: (y) ->
    for x in [0 ... @w]
      @u x, y

  gravity: (y) ->
    for y in [y .. 1]
      for x in [0 ... @w]
        @s x, y @g(x, y - 1)
    @eraseLine 0

        
        
# http://en.wikipedia.org/wiki/Tetris#Gameplay
blocks = [
  new Grid(4,1, [ [0,0], [1,0], [2,0], [3,0] ], '#700') # ---
  new Grid(3,2, [ [0,0], [0,1], [1,1], [2,1] ], '#070') # L_
  new Grid(3,2, [ [2,0], [0,1], [1,1], [2,1] ], '#007') # _J
  new Grid(2,2, [ [0,0], [1,0], [0,1], [1,1] ], '#770') # []
  new Grid(3,2, [ [1,0], [2,0], [0,1], [1,1] ], '#077') # _-
  new Grid(3,2, [ [1,0], [0,1], [1,1], [2,1] ], '#707') # _!_
  new Grid(3,2, [ [0,0], [1,0], [1,1], [2,1] ], '#444') # -_
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
      grid: new Grid(10, 16)
      piece:
        idx: 1
        rot: 0
        pos: [0, 0]
      
    

    # set up canvas
    @cvsEl = document.createElement 'canvas'
    @cvsEl.setAttribute 'width',  @state.grid.w * @cellSize
    @cvsEl.setAttribute 'height', @state.grid.h * @cellSize
    @containerEl.appendChild @cvsEl
    @ctx = @cvsEl.getContext '2d'
      
    @draw()
      
      
      
  draw: () ->
    p = @state.piece
    g = @state.grid
      
    b = blocks2[ p.idx ][ p.rot ]
    g.p b, p.pos
    @drawGrid g, @ctx #, [0, 1]
      
      
      
  drawGrid: (g, ctx, dlt=[0,0]) ->
    gridHasColor = g.color?
    ctx.fillStyle = g.color if gridHasColor
    cs = @cellSize
    for y in [0 ... g.h]
      for x in [0 ... g.w]
        v = g.g(x, y)
       if v
         ctx.fillStyle = v if not gridHasColor
         ctx.fillRect (dlt[0]+x)*cs, (dlt[1]+y)*cs, cs, cs
      

   
  left: () ->
    @state.pos[0] -= 1
    
  right: () ->
    @state.pos[0] += 1
    
  rotR: () ->
    @state.piece.rot -= 1
    
  rotL: () ->
    @state.piece.rot += 1
    
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
