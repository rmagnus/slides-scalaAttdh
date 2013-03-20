###
Caffeine High
    
This is a presentation tool based on impress.js by Bartek Szopka (@bartaz).

It started as a direct port but has moved on enough to start moving out of home and begin
a life of its own.

MIT Licensed.

Copyright 2012 Moritz Grauel (@mo_gr)
###

###
helper functions
###
styleDummy = document.createElement('dummy').style
prefixes = ["Webkit", "Moz", "O", "ms", "Khtml"]
prefixMemory = {}

# find the supported prefix of a property and return it
pfx = (prop) ->
  if (! prefixMemory[prop]?)
    uppercaseProp = prop[0].toUpperCase() + prop.substr(1)
    props = (prop + " " + prefixes.join(uppercaseProp + " ") + uppercaseProp).split(" ")
    prefixMemory[prop] = null
    for property in props
      if styleDummy[property]?
        prefixMemory[prop] = property
        break
  prefixMemory[prop]

byId = (id) ->
  document.getElementById id

getElementFromUrl = () ->
  byId window.location.hash.replace(/^#\!\/?/, "")

toArray = (a) ->
  Array.prototype.slice.call(a)

$$ = ( selector, context = document ) ->
  toArray context.querySelectorAll(selector)

css = ( el, props ) ->
  for styleKey, value of props
    el.style[pfx(styleKey)] = value
  el

###
CSS Helper
###
translate =  ( t ) ->
  " translate3d(" + t.x + "px," + t.y + "px," + t.z + "px) "

rotate = ( r, revert ) ->
  rX = " rotateX(" + r.x + "deg) "
  rY = " rotateY(" + r.y + "deg) "
  rZ = " rotateZ(" + r.z + "deg) "
  if revert then rZ+rY+rX else rX+rY+rZ

scale = ( s ) ->
  " scale(" + s + ") "

###
check support
###
ua = navigator.userAgent.toLowerCase()

supportedBrowser = pfx("perspective")? and ua.search(/(iphone)|(ipod)|(ipad)|(android)/) == -1

###
DOM Elements
###

caffeine = byId "caffeine"

caffeine.className = if supportedBrowser then "" else "caffeine-not-supported"

canvas = document.createElement "div"
canvas.className = "canvas"

toArray(caffeine.childNodes).forEach (slide) -> canvas.appendChild slide

caffeine.appendChild canvas

steps = $$("article", caffeine)

###
Setup the document
###
document.documentElement.style.height = "100%"

css document.body, {
  height: "100%",
  overflow: "hidden"
}

props = {
  position: "absolute",
  transformOrigin: "top left",
  transition: "all 0s ease-in-out",
  transformStyle: "preserve-3d"
}

css caffeine, props
css caffeine, {
  top: "50%",
  left: "50%",
  perspective: "1000px"
}
css canvas, props

current = {
  translate: { x: 0, y: 0, z: 0 },
  rotate:    { x: 0, y: 0, z: 0 },
  scale:     1
}

###
position the slides on the canvas
###

prev = null;
for step, idx in steps
  data = step.dataset
  stepData = {
    translate:
      x: data.x || 0,
      y: data.y || 0,
      z: data.z || 0
      dx: data.dx || 0,
      dy: data.dy || 0,
      dz: data.dz || 0
    rotate:
      x: data.rx || 0,
      y: data.ry || 0,
      z: data.rz || 0,
      dx: data.drx || 0,
      dy: data.dry || 0,
      dz: data.drz || 0
    scale: data.scale || 1
    dScale: data.dscale || 0
    duration: data.duration || 1
    dDuration: data.dduration || 0
  }

  if prev?
    hasRelativeTranslation = stepData.translate.dx || stepData.translate.dy || stepData.translate.dz
    if hasRelativeTranslation
      stepData.translate.x = + stepData.translate.x + 1 * stepData.translate.dx + 1 * prev.stepData.translate.x
      stepData.translate.y = + stepData.translate.y + 1 * stepData.translate.dy + 1 * prev.stepData.translate.y
      stepData.translate.z = + stepData.translate.z + 1 * stepData.translate.dz + 1 * prev.stepData.translate.z
    hasRelativeRotation = stepData.rotate.dx || stepData.rotate.dy || stepData.rotate.dz
    if hasRelativeRotation
      stepData.rotate.x = + stepData.rotate.x + 1 * stepData.rotate.dx + 1 * prev.stepData.rotate.x
      stepData.rotate.y = + stepData.rotate.y + 1 * stepData.rotate.dy + 1 * prev.stepData.rotate.y
      stepData.rotate.z = + stepData.rotate.z + 1 * stepData.rotate.dz + 1 * prev.stepData.rotate.z
    stepData.scale = 1 * stepData.dScale + 1 * prev.stepData.scale if stepData.dScale
    stepData.duration = 1 * stepData.dDuration + 1 * prev.stepData.duration if stepData.dDuration

  step.stepData = stepData;
  step.id = "step-" + idx unless step.id

  css step, {
    position: "absolute",
    transform: "translate(-50%,-50%)" +
      translate(stepData.translate) +
      rotate(stepData.rotate) +
      scale(stepData.scale),
    transformStyle: "preserve-3d"
  }

  prev = step

###
make a given step active
###

active = null;
hashTimeout = null;

select = (el) ->
  return false unless el and el.stepData and el != active

  window.scrollTo 0, 0
  step = el.stepData

  active.classList.remove "active" if active?
  el.classList.add "active"

  caffeine.className = "step-" + el.id

  window.clearTimeout hashTimeout
  hashTimeout = window.setTimeout( () ->
    window.location.hash = "#!/" + el.id
  , 1000)

  target = {
    rotate: {
      x: -parseInt(step.rotate.x, 10),
      y: -parseInt(step.rotate.y, 10),
      z: -parseInt(step.rotate.z, 10)
    },
    translate: {
      x: -step.translate.x,
      y: -step.translate.y,
      z: -step.translate.z
    },
    scale: 1 / parseFloat(step.scale)
  }

  zooming = target.scale >= current.scale

  duration = if active then step.duration + "s" else "0"
  zoomDuration = if active then 0.5 * step.duration + "s" else "0"

  css caffeine, {
    perspective: step.scale * 1000 + "px",
    transform: scale(target.scale),
    transitionDuration: duration,
    transitionDelay: if zooming then zoomDuration else "0ms"
  }

  css canvas, {
    transform: rotate(target.rotate, true) + translate(target.translate),
    transitionDuration: duration,
    transitionDelay: if zooming then "0ms" else zoomDuration
  }

  current = target
  active = el

  activeIndex = steps.indexOf(active)
  for step in steps
    step.classList.remove('past')
    step.classList.remove('future')
  step.classList.add('past') for step in steps when steps.indexOf(step) < activeIndex
  step.classList.add('future') for step in steps when steps.indexOf(step) > activeIndex

selectPrev = () ->
  prev = steps.indexOf( active ) - 1
  prev = if prev >= 0 then steps[prev] else steps[steps.length - 1]
  select prev

selectNext = () ->
  next = steps.indexOf(active) + 1
  next = if next < steps.length then steps[next] else steps[0]
  select next

###
Event Listener
###
document.addEventListener("keydown", (event) ->
  if event.target.tagName == "PRE"
    return
  if event.keyCode in [33, 37, 38]
    selectPrev()
    event.preventDefault()
  if event.keyCode in [9, 32, 34, 39, 40]
    selectNext()
    event.preventDefault()
, false)

document.addEventListener("click", (event) ->
  target = event.target
  while ((target.tagName != "A" or target.tagName != "IFRAME") and not target.stepData and target != document.body)
    target = target.parentNode

  if target.tagName == "A"
    href = target.getAttribute "href"
    target = byId href.slice(1) if href and href[0] == '#'

  if select target
    event.preventDefault()
, false)

window.addEventListener("hashchange", () ->
  select getElementFromUrl()
, false)

window.addEventListener("touchstart", (event) ->
  touchLocation = event.touches[0].pageX / document.body.clientWidth
  if touchLocation < 0.5 then selectPrev() else selectNext()
)

select getElementFromUrl() || steps[0]

###
Expose the Caffeine High API
###

@CaffeineHigh = {
  next: selectNext
  prev: selectPrev
}
