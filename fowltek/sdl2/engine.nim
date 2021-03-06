## This is a minimal engine for rapid prototyping
## functionality included:
## * assisted window and renderer creation
## * easy to use event handling system
import fowltek/sdl2, fowltek/sdl2/gfx
import fowltek/maybe_t, unsigned

template import_all_sdl2_modules*: stmt =
  import fowltek/sdl2, fowltek/sdl2/image, fowltek/sdl2/gfx, fowltek/sdl2/ttf
template import_all_sdl2_helpers*: stmt =
  when not defined(toSDLcolor): 
    import fowltek/sdl2/color
  when not defined(spriteCache):
    import fowltek/sdl2/spritecache
template import_all_sdl2_things*: stmt =
  import_all_sdl2_modules
  import_all_sdl2_helpers

type 
  TSdlEventHandler* = proc(engine: PSdlEngine): bool
  TSdlEventHandlerSeq* = seq[TSdlEventHandler]
  
  PSDLEngine* = var TSdlEngine
  TSDLEngine* = object
    window*: PWindow
    render*: PRenderer
    evt*: TEvent
    eventHandlers*: TMaybe[TSDLEventHandlerSeq]
    fpsMan*: TFpsManager
    lastTick*: uint32

proc destroy* (some: PSdlEngine) {.inline.} =
  destroy some.render
  destroy some.window

proc newSDLEngine*(
    caption = "SDL Game", 
    startX, startY = 100, 
    sizeX = 640, sizeY = 480,
    renderFlags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
                  ): TSdlEngine =
  
  discard SDL_Init (INIT_EVERYTHING)
  result.window = CreateWindow(caption, startX.cint, startY.cint, 
    sizeX.cint, sizeY.cint, SDL_WINDOW_SHOWN)
  result.render = result.window.createRenderer(-1, 
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  
  result.fpsMan.init
  result.lastTick = sdl2.getTicks()

proc addHandler*(some: PSdlEngine; handler: TSdlEventHandler) =
  if some.eventHandlers:
    some.eventHandlers.val.add handler
  else:
    some.eventHandlers = Just(@[ handler ])

proc handleEvent* (handlers: seq[proc(X: var TEvent): bool]; event: var TEvent): bool =
  for h in handlers:
    if h(event): return true

proc pollHandle*(some: PSdlEngine): bool {.inline.} =
  ## Returns true if an event was polled.
  result = some.evt.pollEvent
  if result and some.eventHandlers:
    for eh in some.eventHandlers.val:
      if eh(some): break

proc handleEvents*(some: PSdlEngine) {.inline.} =
  while some.pollHandle:
    nil

proc frameDeltaMS*(some: PSdlEngine): int32 {.
  inline.} = 
  ## Calculate the delta MS from the last frame.
  ## This is no use unless you call it once a frame.
  let cur = sdl2.getTicks()
  result = int32(cur - some.lastTick)
  some.lastTick = cur
  
proc frameDeltaFlt*(some: PSdlEngine): float {.
  inline.} = some.frameDeltaMS / 1000

proc delay*(some: PSdlEngine) {.inline.} =
  ## wait for fpsMan (use this or Renderer_PresentVSync to limit the framerate)
  some.fpsMan.delay
proc delay*(some: PSdlEngine; ms: uint32) {.inline.} =
  ## wait for `ms` milliseconds
  sdl2.delay ms

converter toRenderer*(some: PSdlEngine): sdl2.PRenderer = some.render


import fowltek/vector_math, math

proc degrees2radians*(deg: float): float {.inline.} = deg * pi / 180.0
proc radians2degrees*(rad: float): float {.inline.} = (rad * 180.0 / PI) mod 360.0

## these functions are intended to work with sdl's coordinate system 
proc vectorToAngle* (some: TVector2[float]): float = arctan2(some.y, some.x)
  # return the angle in radians
proc vectorForAngle*(radians: float): TVector2[float] {.inline.} = (
  x: cos(radians), y: sin(radians))
  # return the vector for given radians


when isMainModule:
  var e = newSDLengine(sizeX = 640, sizeY = 480)
  var running = true
  e.addHandler proc(E: PSdlEngine): bool =
    result = e.evt.kind == QuitEvent
    if result:
      running = false
  
  import strutils
  
  while running:
    e.handleEvents
    ## if you dont want to use the event handlers ->
    ## if e.pollHandle: 
    ##   # do stuff with e.evt
    let dt = e.frameDeltaFlt
    
    e.render.setDrawColor 0,0,0,255
    e.render.clear
    
    e.render.present

  destroy e
