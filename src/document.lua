local json = require("dkjson")
local mongo = require("mongo")
local checkargs = require("checkargs")
local class = require("middleclass")
local QuerySet = require("moongo.queryset")
local BaseField = require("moongo.fields").BaseField
local utils = require("moongo.utils")

local documents = {}

local EmbeddedDocument = class("EmbeddedDocument")

function EmbeddedDocument.__index(self, key)
    local values = rawget(self, "values")
    if values and next(values) ~= nil and values[key] then
        return values[key]
    else
        return rawget(self, key) or EmbeddedDocument[key]
    end
end

function EmbeddedDocument:initialize(fields)
    checkargs.check_arg("EmbeddedDocument:new", "fields", { "table" }, fields)
    self.fields = {}
    self.values = {}

    for name, field in pairs(fields) do
        if type(field) == "table" and field:isInstanceOf(BaseField) then
            if not self.fields[name] then
                self.fields[name] = field
            else
                error(utils.format_error("EmbeddedDocument:new", "Fields with repeated names:" .. name))
            end
        else
            error(utils.format_error("EmbeddedDocument:new", "Fields must be a instance of BaseField"))
        end
    end
end

function EmbeddedDocument:__call(values)
    if not next(self.fields) then
        error(utils.format_error("EmbeddedDocument:__call", "Fields not defined"))
    end

    for key, value in pairs(values) do
        local field = self.fields[key]
        if field then
            local is_valid, result = field:validate(key, value)
            if not is_valid then
                error(result)
            else
                self.values[key] = result
            end
        else
            error(utils.format_error("EmbeddedDocument:__call", "Field '" .. key .. "' not found in document schema"))
        end
    end
    return self
end

function EmbeddedDocument:__pairs()
    return pairs(self.values)
end

function EmbeddedDocument:__ipairs()
    return ipairs(self.values)
end

local Document = class("Document")

function Document.__index(self, key)
    local values = rawget(self, "values")
    if values and next(values) ~= nil and values[key] then
        return values[key]
    else
        return rawget(self, key) or Document[key]
    end
end

function Document.static:subclassed(subclass)
    subclass.static.fields = {}
    subclass.static.queryset = QuerySet
    subclass.static.collection_name = subclass.name:lower()
end

function Document.static:set_config(config)
    checkargs.check_arg("Document:set_config", "config", { "table" }, config)
    self.static.database = config.database
    self.static.collection_name = config.collection or self.static.collection_name
    self.static.queryset = config.queryset or self.static.queryset
    self.static.event_emitter = config.event_emitter
    self.static.indexes = config.indexes
    self.static.objects = self.static.queryset:new(self)
    return self
end

function Document.static:set_fields(fields)
    checkargs.check_arg("Document:set_fields", "fields", { "table" }, fields)
    for name, field in pairs(fields) do
        self:add_field(name, field)
    end
    return self
end

function Document.static:add_field(name, field)
    checkargs.check_arg(self.name .. ":add_field", "name", { "string" }, name)
    checkargs.check_arg(self.name .. ":add_field", "field", { "table" }, field)
    if type(field) == "table" and field:isInstanceOf(BaseField) then
        if not self.static.fields[name] then
            self.static.fields[name] = field
        else
            error(utils.format_error("Document:add_field", "Fields with repeated names:" .. name))
        end
    else
        error(utils.format_error("Document:add_field", "Fields must be a instance of BaseField"))
    end
    return self
end

function Document.static:remove_field(name)
    checkargs.check_arg(self.name .. ":remove_field", "name", { "string" }, name)
    self.static.fields[name] = nil
end

function Document.static:get_fields()
    local fields = self.static.fields
    if not fields then
        error(utils.format_error("Document:get_fields", "Document fields not defined"))
    end
    return fields
end

function Document.static:get_field(name)
    checkargs.check_arg("Document:get_field", "name", { "string" }, name)
    return self:get_fields()[name]
end

function Document.static:get_database()
    local database = self.static.database
    if not database then
        error(utils.format_error("Document:get_database", "Not connection made to database"))
    end
    return database
end

function Document.static:get_collection()
    local database = self:get_database()
    local collection_name = self.static.collection_name
    return database:getCollection(collection_name)
end

function Document.static:from_json(json_data)
    checkargs.check_arg("Document:from_json", "json_data", { "string" }, json_data)
    local document_fields = {}
    local document_data, pos, err = json.decode(json_data, 1, nil)
    if err ~= nil then
        error(utils.format_error("Document:from_json", err))
    end

    for name, value in pairs(document_data) do
        local field = self:get_field(name)
        if field then
            local is_valid, error_message = field:validate(value)
            if not is_valid then
                error(error_message)
            end

            document_fields[name] = value
        end
    end

    return self:new(document_fields)
end

function Document.static:get_event_emitter()
    local event_emitter = self.static.event_emitter
    if not event_emitter then
        error(utils.format_error("Document:get_event_emitter", "Event emitter not defined"))
    end
    return event_emitter
end

function Document.static:on_event(name, listener)
    local event_emitter = self:get_event_emitter()
    event_emitter:on(name, listener)
end

function Document.static:off_event(name, listener)
    local event_emitter = self:get_event_emitter()
    event_emitter:off(name, listener)
end

function Document.static:emit_event(name, ...)
    local success, result = pcall(function()
        return self:get_event_emitter()
    end)

    if success then
        result:emit(name, self, ...)
        return true
    end
    return false
end

function Document:initialize(values)
    checkargs.check_arg("Document:new", "values", { "table" }, values)
    self.class:emit_event("before_init", values)
    self.values = self:_validate_values(values)
    self.objects = self.class.static.objects

    if self.class.static.indexes ~= nil then
        local collection = self.class:get_collection()
        for _, index in ipairs(self.class.static.indexes) do
            collection:createIndex(index.indexes, index.options)
        end
    end
    self.class:emit_event("after_init", self.values)
end

function Document:_validate_values(values)
    for key, value in pairs(values) do
        if key ~= "_id" then
            local field = self.class:get_field(key)
            if field ~= nil then
                local is_valid, result = field:validate(key, value)
                if not is_valid then
                    error(result)
                end
            else
                error(utils.format_error("Document:_validate_values",
                    "field '" .. key .. "' not found in document schema"))
            end
        end
    end

    if not values._id then
        values._id = mongo.ObjectID()
    end
    return values
end

function Document:__pairs()
    return pairs(self.values)
end

function Document:__ipairs()
    return ipairs(self.values)
end

function Document:to_json()
    return json.encode(self.values)
end

function Document:save()
    self.class:emit_event("before_save")
    local result = self.objects:insert(self.values)
    self.class:emit_event("after_save")
    return result
end

function Document:delete()
    self.class:emit_event("before_delete")
    self.objects:filter(self.values):delete()
    self.values = {}
    self.class:emit_event("after_delete")
end

function Document:drop(options)
    checkargs.check_arg("Document:drop", "options", { "table" }, options, true)
    local collection = self:get_collection()
    return collection:drop(options)
end

documents.Document = Document
documents.EmbeddedDocument = EmbeddedDocument

return documents
