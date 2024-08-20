local mongo = require("mongo")
local class = require("middleclass")
local documents = require("moongo.document")
local fields = require("moongo.fields")
local signals = require("moongo.signals")
local Signal = signals.Signal
local EventEmitter = signals.EventEmitter

-- Test Functions
local function test_signal_initialization()
    local signal = Signal:new()
    assert(#signal.listeners == 0, "Failed to initialize Signal with empty listeners")
end

local function test_signal_connect()
    local signal = Signal:new()
    local function dummy_listener() end
    signal:connect(dummy_listener)
    assert(#signal.listeners == 1, "Failed to connect listener to Signal")
    assert(signal.listeners[1] == dummy_listener, "Connected listener is incorrect")
end

local function test_signal_disconnect()
    local signal = Signal:new()
    local function dummy_listener() end
    signal:connect(dummy_listener)
    signal:disconnect(dummy_listener)
    assert(#signal.listeners == 0, "Failed to disconnect listener from Signal")
end

local function test_signal_emit()
    local signal = Signal:new()
    local emitted = false
    local function dummy_listener(sender, message)
        emitted = true
        assert(sender == "test_sender", "Sender is incorrect in Signal emit")
        assert(message == "test_message", "Message is incorrect in Signal emit")
    end
    signal:connect(dummy_listener)
    signal:emit("test_sender", "test_message")
    assert(emitted, "Failed to emit signal to listener")
end

local function test_eventemitter_initialization()
    local emitter = EventEmitter:new()
    assert(next(emitter.events) == nil, "Failed to initialize EventEmitter with empty events")
end

local function test_eventemitter_on()
    local emitter = EventEmitter:new()
    local function dummy_listener() end
    emitter:on("test_event", dummy_listener)
    assert(emitter.events["test_event"], "Failed to create Signal for event in EventEmitter")
    assert(#emitter.events["test_event"].listeners == 1, "Failed to add listener to event in EventEmitter")
end

local function test_eventemitter_off()
    local emitter = EventEmitter:new()
    local function dummy_listener() end
    emitter:on("test_event", dummy_listener)
    emitter:off("test_event", dummy_listener)
    assert(#emitter.events["test_event"].listeners == 0, "Failed to remove listener from event in EventEmitter")
end

local function test_eventemitter_emit()
    local emitter = EventEmitter:new()
    local emitted = false
    local function dummy_listener(sender, message)
        emitted = true
        assert(sender == "test_sender", "Sender is incorrect in EventEmitter emit")
        assert(message == "test_message", "Message is incorrect in EventEmitter emit")
    end
    emitter:on("test_event", dummy_listener)
    emitter:emit("test_event", "test_sender", "test_message")
    assert(emitted, "Failed to emit event to listener in EventEmitter")
end

local function test_document_events()
    local fields = {
        name = fields.BaseField:new(),
        age = fields.BaseField:new()
    }
    local config = {
        database = mongo.Client("mongodb://localhost:27017"):getDatabase("test_db"),
        collection = "test_collection",
        event_emitter = EventEmitter:new()
    }
    local DocumentClass = class("TestDocument", documents.Document)
    DocumentClass:set_config(config)
    DocumentClass:set_fields(fields)

    local values = { name = "Moongo", age = 35 }
    local before_values = values
    local after_values = values

    DocumentClass:on_event("before_init", function(values)
        before_values = { name = "Before" }
    end)

    DocumentClass:on_event("after_init", function(values)
        after_values = { name = "After" }
    end)

    DocumentClass:new(values)
    assert(before_values.name == "Before" and after_values.name == "After", "Document events: Events listeners failed")
end

-- Run Tests
local function runtests()
    test_signal_initialization()
    test_signal_connect()
    test_signal_disconnect()
    test_signal_emit()
    test_eventemitter_initialization()
    test_eventemitter_on()
    test_eventemitter_off()
    test_eventemitter_emit()
    test_document_events()
    print("All tests passed successfully!")
end

runtests()
