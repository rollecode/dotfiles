-- luacheck: globals hs clickHandler dragHandler cancelHandler
-- Hammerspoon config for Cmd + Mouse window management
-- Based on SkyRocket.spoon by David Balatero
-- Cmd + Left Mouse: Move window
-- Cmd + Right Mouse: Resize window

local dragTypes = {
  move = 1,
  resize = 2,
}

local state = {
  dragging = false,
  dragType = nil,
  targetWindow = nil,
  windowCanvas = nil,
}

-- Create canvas for visual preview
local function createCanvas()
  local canvas = hs.canvas.new{}
  canvas:insertElement({
    action = 'fill',
    type = 'rectangle',
    fillColor = { red = 0, green = 0, blue = 0, alpha = 0.3 },
    roundedRectRadii = { xRadius = 5.0, yRadius = 5.0 },
  })
  return canvas
end

-- Get window under mouse cursor
local function getWindowUnderMouse()
  local _ = hs.application  -- Needed to make hs.window.orderedWindows() work
  local mousePos = hs.geometry.new(hs.mouse.absolutePosition())
  local mouseScreen = hs.mouse.getCurrentScreen()

  return hs.fnutils.find(hs.window.orderedWindows(), function(w)
    return mouseScreen == w:screen() and mousePos:inside(w:frame())
  end)
end

-- Initialize canvas to match window
local function resizeCanvasToWindow()
  if not state.targetWindow then return end

  local position = state.targetWindow:topLeft()
  local size = state.targetWindow:size()

  state.windowCanvas:topLeft({ x = position.x, y = position.y })
  state.windowCanvas:size({ w = size.w, h = size.h })
end

-- Apply canvas size to window
local function resizeWindowToCanvas()
  if not state.targetWindow or not state.windowCanvas then return end

  local size = state.windowCanvas:size()
  state.targetWindow:setSize(size.w, size.h)
end

-- Apply canvas position to window
local function moveWindowToCanvas()
  if not state.targetWindow or not state.windowCanvas then return end

  local frame = state.windowCanvas:frame()
  local point = state.windowCanvas:topLeft()

  state.targetWindow:move(hs.geometry.new({
    x = point.x,
    y = point.y,
    w = frame.w,
    h = frame.h,
  }), nil, false, 0)
end

-- Stop dragging operation
local function stopDragging()
  state.dragging = false
  state.dragType = nil
  state.windowCanvas:hide()
  cancelHandler:stop()
  dragHandler:stop()
  clickHandler:start()
end

-- Handle mouse click to start operation
clickHandler = hs.eventtap.new(
  {
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.rightMouseDown,
  },
  function(event)
    if state.dragging then return true end

    local flags = event:getFlags()
    local eventType = event:getType()

    -- Check for Cmd (no other modifiers)
    local isMoving = eventType == hs.eventtap.event.types.leftMouseDown and
                     flags.cmd and not flags.shift and not flags.alt and not flags.ctrl
    local isResizing = eventType == hs.eventtap.event.types.rightMouseDown and
                       flags.cmd and not flags.shift and not flags.alt and not flags.ctrl

    if isMoving or isResizing then
      local currentWindow = getWindowUnderMouse()
      if not currentWindow then return nil end

      state.dragging = true
      state.targetWindow = currentWindow

      if isMoving then
        state.dragType = dragTypes.move
      else
        state.dragType = dragTypes.resize
      end

      resizeCanvasToWindow()
      state.windowCanvas:show()

      cancelHandler:start()
      dragHandler:start()
      clickHandler:stop()

      currentWindow:focus()
      return true
    else
      return nil
    end
  end
)

-- Handle mouse drag to update preview
dragHandler = hs.eventtap.new(
  {
    hs.eventtap.event.types.leftMouseDragged,
    hs.eventtap.event.types.rightMouseDragged,
  },
  function(event)
    if not state.dragging then return nil end

    local dx = event:getProperty(hs.eventtap.event.properties.mouseEventDeltaX)
    local dy = event:getProperty(hs.eventtap.event.properties.mouseEventDeltaY)

    if state.dragType == dragTypes.move then
      local current = state.windowCanvas:topLeft()
      state.windowCanvas:topLeft({
        x = current.x + dx,
        y = current.y + dy,
      })
      return true
    elseif state.dragType == dragTypes.resize then
      local currentSize = state.windowCanvas:size()
      state.windowCanvas:size({
        w = math.max(200, currentSize.w + dx),
        h = math.max(100, currentSize.h + dy)
      })
      return true
    else
      return nil
    end
  end
)

-- Handle mouse release to commit changes
cancelHandler = hs.eventtap.new(
  {
    hs.eventtap.event.types.leftMouseUp,
    hs.eventtap.event.types.rightMouseUp,
  },
  function()
    if not state.dragging then return end

    if state.dragType == dragTypes.resize then
      resizeWindowToCanvas()
    else
      moveWindowToCanvas()
    end

    stopDragging()
  end
)

-- Initialize
state.windowCanvas = createCanvas()
clickHandler:start()

-- Show notification
hs.notify.new({
  title = "Hammerspoon",
  informativeText = "Cmd+Mouse window management loaded\n\nCmd+LeftMouse: Move\nCmd+RightMouse: Resize"
}):send()

-- Auto-reload config on changes
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

print("✓ Hammerspoon loaded: Cmd+LeftMouse=Move, Cmd+RightMouse=Resize")
