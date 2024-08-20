local class = require("middleclass")
local checkargs = require("checkargs")

local signals = {}

local Signal = class("Signal")

function Signal:initialize()
    self.listeners = {}
end

function Signal:connect(listener)
    checkargs.check_arg("Signal:connect", "listeners", { "function" }, listener)
    table.insert(self.listeners, listener)
end

function Signal:disconnect(listener)
    checkargs.check_arg("Signal:disconnect", "listeners", { "function" }, listener)
    for i, v in ipairs(self.listeners) do
        if v == listener then
            table.remove(self.listeners, i)
            break
        end
    end
end

function Signal:emit(sender, ...)
    for _, listener in ipairs(self.listeners) do
        listener(sender, ...)
    end
end

EventEmitter = class("EventEmitter")

function EventEmitter:initialize()
    self.events = {}
end

function EventEmitter:on(event, listener)
    if not self.events[event] then
        self.events[event] = Signal:new()
    end
    self.events[event]:connect(listener)
end

function EventEmitter:off(event, listener)
    if self.events[event] then
        self.events[event]:disconnect(listener)
    end
end

function EventEmitter:emit(event, sender, ...)
    if self.events[event] then
        self.events[event]:emit(sender, ...)
    end
end

signals.Signal = Signal
signals.EventEmitter = EventEmitter

return signals
