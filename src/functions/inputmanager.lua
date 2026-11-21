-- INPUT MANAGER / MONITOR
SurplusInputManager = {
  double_click_window = 0.3,
  last_clicked = {
    target = nil,
    time = 0,
  },
  subscribers = {
    ['left_click'] = {},
    ['right_click'] = {},
    ['double_click'] = {},
    ['right_stick'] = {},
    ['x'] = {},
  }
}

function SurplusInputManager:add_listener(event, func)
  if type(event) ~= 'table' then event = { event } end
  for _, e in ipairs(event) do
    table.insert(self.subscribers[e], func)
  end
end

function SurplusInputManager:fire_event(event, payload)
  for _, func in ipairs(self.subscribers[event]) do
    func(payload)
  end
end

function SurplusInputManager:handle_double_click(target)
  local current_time = love.timer.getTime()
  if self.last_clicked.target == target
      and current_time - self.last_clicked.time <= self.double_click_window then
    self:double_click(target)
    self.last_clicked.target = nil
    self.last_clicked.time = 0
  else
    self.last_clicked.target = target
    self.last_clicked.time = current_time
  end
end

function SurplusInputManager:double_click(target)
  self:fire_event('double_click', target)
end

function SurplusInputManager:left_click(target)
  if target then
    self:fire_event('left_click', target)
    self:handle_double_click(target)
  end
end

function SurplusInputManager:right_click(target)
  if target then
    self:fire_event('right_click', target)
  end
end

function SurplusInputManager:right_stick(target)
  if target then
    self:fire_event('right_stick', target)
  end
end

function SurplusInputManager:controller_x(target)
  if target then
    self:fire_event('x', target)
  end
end

function SurplusInputManager.is_shift_held()
  return love.keyboard.isDown("lshift")
      or love.keyboard.isDown("rshift")
      or G.CONTROLLER.held_buttons.triggerleft
      or false
end

local controller_is_locked = function()
  return (G.CONTROLLER.locked and (not G.SETTINGS.paused or G.screenwipe))
      or G.CONTROLLER.locks.frame
end

RerollSurplus.Hook("before", G.CONTROLLER, "L_cursor_press", function(self)
  if not controller_is_locked() then
    local target = (self.HID.touch and self.cursor_hover.target) or self.hovering.target or self.focused.target
    SurplusInputManager:left_click(target)
  end
end)

RerollSurplus.Hook("before", G.CONTROLLER, "queue_R_cursor_press", function(self)
  if not controller_is_locked() then
    local target = self.hovering.target or self.focused.target
    SurplusInputManager:right_click(target)
  end
end)

RerollSurplus.Hook("before", G.CONTROLLER, "capture_focused_input", function(self, button, input_type, dt)
  if input_type == 'press' and self.focused then
    local target = self.focused.target
    if button == 'rightstick' then
      SurplusInputManager:right_stick(target)
    elseif button == 'x' then
      SurplusInputManager:controller_x(target)
    end
  end
end)