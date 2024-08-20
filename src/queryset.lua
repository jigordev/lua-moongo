local checkargs = require("checkargs")
local class = require("middleclass")
local utils = require("moongo.utils")

local QuerySet = class("QuerySet")

function QuerySet:initialize(document)
    checkargs.check_arg("QuerySet:new", "document", { "table" }, document)
    self.document = document
    self.collection = self.document:get_collection()
    self.query = {}
    self.options = {}
    self.current_page = 1
    self.page_size = nil
end

function QuerySet:__ipairs()
    return ipairs(self:all())
end

function QuerySet:__pairs()
    return pairs(self:all())
end

function QuerySet:_clear_query()
    self.query = {}
end

function QuerySet:filter(filter, options)
    checkargs.check_arg("QuerySet:filter", "filter", { "table" }, filter)
    checkargs.check_arg("QuerySet:filter", "options", { "table" }, options, true)

    self:_clear_query()
    self.query = filter or {}
    self.options = options or {}
    return self
end

function QuerySet:paginate(page_number, page_size)
    checkargs.check_arg("QuerySet:paginate", "page_number", { "number" }, page_number)
    checkargs.check_arg("QuerySet:paginate", "page_size", { "number" }, page_size)
    self.current_page = page_number
    self.page_size = page_size
    self.options.skip = (self.current_page - 1) * self.page_size
    self.options.limit = self.page_size
end

function QuerySet:get()
    local cursor = self.collection:find(self.query, self.options)
    local result = cursor:next()
    if result ~= nil then
        local values = result:value()
        if values ~= nil then
            return self.document:new(values)
        end
    end
    error(utils.format_error("QuerySet:get", "Document not found"))
end

function QuerySet:all()
    local cursor = self.collection:find(self.query, self.options)
    local results = {}
    for values in cursor:iterator() do
        local instance = self.document:new(values)
        table.insert(results, instance)
    end
    return results
end

function QuerySet:first()
    local previous_limit = self.options.limit
    self.options.limit = 1
    local cursor = self.collection:find(self.query, self.options)
    self.options.limit = previous_limit -- Reset limit to previous value
    local result = cursor:next()
    if result ~= nil then
        local values = result:value()
        if values ~= nil then
            return self.document:new(values)
        end
    end
    return result
end

function QuerySet:exclude(exclude_filter)
    checkargs.check_arg("QuerySet:exclude", "exclude_filter", { "table" }, exclude_filter)
    local merged_query = { ["$and"] = { self.query, { ["$nor"] = { exclude_filter } } } }
    return self:filter(merged_query, self.options)
end

function QuerySet:only(...)
    local fields = { ... }
    local projection = {}
    for _, field in ipairs(fields) do
        projection[field] = 1
    end
    self.options.projection = projection
    return self
end

function QuerySet:search_text(query)
    checkargs.check_arg("QuerySet:search_text", "query", { "string" }, query)
    self.options["$text"] = { ["$search"] = query }
    return self
end

function QuerySet:order_by(field, direction)
    checkargs.check_arg("QuerySet:order_by", "field", { "string" }, field)
    checkargs.check_arg("QuerySet:order_by", "direction", { "number" }, direction)
    if direction ~= 1 and direction ~= -1 then
        error(utils.format_error("QuerySet:order_by", "Direction must be 1 (ascending) or -1 (descending)"))
    end
    self.options.sort = { [field] = direction }
    return self
end

function QuerySet:limit(limit)
    checkargs.check_arg("QuerySet:limit", "limit", { "number" }, limit)
    self.options.limit = limit
    return self
end

function QuerySet:delete()
    return self.collection:removeMany(self.query, self.options)
end

function QuerySet:count()
    return self.collection:count(self.query, self.options)
end

function QuerySet:exists()
    local cursor = self.collection:find(self.query, self.options)
    return cursor:next() ~= nil
end

function QuerySet:aggregate(pipeline, options)
    checkargs.check_arg("QuerySet:aggregate", "pipeline", { "string" }, pipeline)
    checkargs.check_arg("QuerySet:aggregate", "options", { "table" }, options, true)
    local cursor = self.collection:aggregate(pipeline, options)

    local result
    if cursor:iterator() ~= nil then
        result = {}
        for values in cursor:iterator() do
            if type(values) == "table" then
                table.insert(result, self.document:new(values))
            else
                table.insert(result, values)
            end
        end
        return result
    end

    result = cursor:value()
    if result ~= nil then
        if type(result) == "table" then
            result = self.document:new(result)
        end
    end
    return result
end

function QuerySet:skip(skip)
    checkargs.check_arg("QuerySet:skip", "skip", { "number" }, skip)
    self.options.skip = skip
    return self
end

function QuerySet:insert(...)
    local result, error_message = self.collection:insertMany(...)
    if not result then
        error(utils.format_error("QuerySet:insert", error_message))
    end
    return result
end

function QuerySet:update(filter, update_fields)
    checkargs.check_arg("QuerySet:update", "filter", { "table" }, filter)
    checkargs.check_arg("QuerySet:update", "update_fields", { "table" }, update_fields)

    local result, error_message = self.collection:updateMany(filter, { ["$set"] = update_fields }, self.options)
    if not result then
        error(utils.format_error("QuerySet:update", error_message))
    end
    return result
end

function QuerySet:update_one(filter, update_fields)
    checkargs.check_arg("QuerySet:update_one", "filter", { "table" }, filter)
    checkargs.check_arg("QuerySet:update_one", "update_fields", { "table" }, update_fields)

    self.options.upsert = self.options.upsert or false
    self.options.multi = self.options.multi or false
    local result, error_message = self.collection:updateOne(filter, { ["$set"] = update_fields }, self.options)
    if not result then
        error(utils.format_error("QuerySet:update_one", error_message))
    end
    return result
end

return QuerySet
