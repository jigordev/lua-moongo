local checkargs = require("checkargs")
local class = require("middleclass")
local utils = require("moongo.utils")

local fields = {}

local BaseField = class("BaseField")

function BaseField:initialize(options)
    checkargs.check_arg("BaseField:new", "options", { "table" }, options, true)
    self.options = options or {}
end

function BaseField:validate(key, value)
    if not next(self.options) then
        return true, value
    end

    if self.options.required and (value == nil) then
        return false, utils.format_error("BaseField:validate", "field " .. key .. " is required")
    end

    if self.options.default and (value == nil) then
        value = self.options.default
    end

    if self.options.choices and not utils.contains(self.options.choices, value) then
        return false,
            utils.format_error("BaseField:validate", "value " .. value .. " is not one of the choices")
    end

    if self.options.validators then
        for _, validator in ipairs(self.options.validators) do
            if type(validator) ~= "function" then
                return false,
                    utils.format_error("BaseField:validate", "validators must be a functions, got: " .. type(validator))
            end

            local success, error_message = validator(value)
            if not success then
                return false, utils.format_error("BaseField:validate", error_message)
            end
        end
    end

    if self.options.filters then
        for _, filter in ipairs(self.options.filters) do
            if type(filter) ~= "function" then
                return false,
                    utils.format_error("BaseField:validate", "filters must be a functions, got: " .. type(filter))
            end

            value = filter(value)
        end
    end

    return true, value
end

local StringField = class("StringField", BaseField)

function StringField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "string" then
        return false, utils.format_error("StringField:validate", "field " .. key .. " must be a string")
    end

    if self.options.max_length and #value > self.options.max_length then
        return false,
            utils.format_error("StringField:validate", "field " .. key .. " exceeds maximum length")
    end

    if self.options.min_length and #value < self.options.min_length then
        return false,
            utils.format_error("StringField:validate",
                "field " .. key .. " is shorter than minimum length")
    end

    if self.options.regex and not string.match(value, self.options.regex) then
        return false,
            utils.format_error("StringField:validate", "field " .. key .. " does not match regex pattern")
    end

    if self.options.trim then
        value = utils.trim(value)
    end

    if self.options.lowercase then
        value = string.lower(value)
    end

    if self.options.uppercase then
        value = string.upper(value)
    end

    return true, value
end

local IntField = class("IntField", BaseField)

function IntField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "number" and math.floor(value) == value then
        return false, utils.format_error("IntField:validate", "field " .. key .. " must be a integer")
    end

    if self.options.max_value and value > self.options.max_value then
        return false,
            utils.format_error("IntField:validate", "field " .. key .. " exceeds maximum value")
    end

    if self.options.min_value and value < self.options.min_value then
        return false,
            utils.format_error("IntField:validate", "field " .. key .. " is less than minimum value")
    end

    return true, value
end

local FloatField = class("FloatField", BaseField)

function FloatField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "number" and math.floor(value) ~= value then
        return false, utils.format_error("FloatField:validate", "field " .. key .. " must be a flot")
    end

    if self.options.max_value and value > self.options.max_value then
        return false,
            utils.format_error("FloatField:validate", "field " .. key .. " exceeds maximum value")
    end

    if self.options.min_value and value < self.options.min_value then
        return false,
            utils.format_error("FloatField:validate", "field " .. key .. " is less than minimum value")
    end

    if self.options.precision and value ~= math.floor(value + self.options.precision) then
        return false,
            utils.format_error("FloatField:validate",
                "field " .. key .. " does not meet precision requirement")
    end

    if not self.options.nan_allowed and value ~= value then
        return false,
            utils.format_error("FloatField:validate", "field " .. key .. "NaN value is not allowed")
    end

    if not self.options.inf_allowed and (value == math.huge or value == -math.huge) then
        return false,
            utils.format_error("FloatField:validate", "field " .. key .. "infinite value is not allowed")
    end

    return true, value
end

local BooleanField = class("BooleanField", BaseField)

function BooleanField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "boolean" then
        return false,
            utils.format_error("BooleanField:validate", "field " .. key .. " must be a boolean")
    end

    return true, value
end

local DateTimeField = class("DateTimeField", BaseField)

function DateTimeField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    local now = os.date("%Y-%m-%d %H:%M:%S")
    if self.options.auto_now or (self.options.auto_now_add and not value) then
        value = now
    end

    return true, value
end

local ListField = class("ListField", BaseField)

function ListField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if not utils.is_list(value) then
        return false, utils.format_error("ListField:validate", "invalid list provided")
    end

    if self.options.min_length and #value < self.options.min_length then
        return false,
            utils.format_error("ListField:validate",
                "field " .. key .. " list length is less than the minimum required")
    end

    if self.options.max_length and #value > self.options.max_length then
        return false,
            utils.format_error("ListField:validate",
                "field " .. key .. " list length exceeds the maximum allowed")
    end

    if self.options.item_type then
        for _, item in ipairs(value) do
            if type(item) ~= self.options.item_type then
                return false,
                    utils.format_error("ListField:validate",
                        "field " .. key .. " list contains items of incorrect type")
            end
        end
    end

    return true, value
end

local TableField = class("TableField", BaseField)

function TableField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if self.options.schema then
        for key, value in pairs(value) do
            local schema_field = self.options.schema[key]
            if not schema_field then
                return false,
                    utils.format_error("TableField:validate",
                        "field " .. key .. " unknown field in table")
            end
            if type(value) ~= schema_field.type then
                return false, "table does not match the schema"
            end
        end
    end

    if self.options.min_length and #value < self.options.min_length then
        return false,
            utils.format_error("TableField:validate",
                "field " .. key .. " table length is less than the minimum required")
    end

    if self.options.max_length and #value > self.options.max_length then
        return false,
            utils.format_error("TableField:validate",
                "field " .. key .. " table length exceeds the maximum allowed")
    end

    return true, value
end

local ReferenceField = class("ReferenceField", BaseField)

function ReferenceField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "table" then
        return false,
            utils.format_error("ReferenceField:validate",
                "field " .. key .. " the reference is not a valid document")
    end

    return true, value._id
end

local EmbeddedDocumentField = class("EmbbededDocumentField", BaseField)

function EmbeddedDocumentField:initialize(embedded, options)
    checkargs.check_arg("EmbeddedDocumentField:new", "embedded", { "table" }, embedded)
    BaseField.initialize(self, options)
    self.embedded = embedded
end

function EmbeddedDocumentField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "table" then
        return false,
            utils.format_error("EmbeddedDocumentField:validate",
                "field " .. key .. " the reference is not a valid embedded document")
    end

    local success, result = pcall(function()
        return self.embedded(value)
    end)

    if not success or not result then
        return false, result
    end

    return true, result.values
end

local FileField = class("FileField", BaseField)

function FileField:initialize(gridfs, options)
    checkargs.check_arg("FileField:new", "gridfs", { "table" }, gridfs)
    BaseField.initialize(self, options)
    self.file = gridfs:createFile(self.options)
end

function FileField:validate(key, value)
    local is_valid, error_message = BaseField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    if type(value) ~= "string" then
        return false, utils.format_error("FileField:validate", "field " .. key .. " must be a string (file content)")
    end

    if not self.file:write(value) then
        return false, utils.format_error("FileField:validate", "impossible to save file contents")
    end

    return true, self.file
end

local ImageField = class("ImageField", FileField)

function ImageField:validate(key, value)
    local is_valid, error_message = FileField.validate(self, key, value)

    if not is_valid then
        return false, error_message
    end

    local allowed_types = self.options.allowed_types or { "image/jpeg", "image/png", "image/gif" }
    local file_type = utils.get_file_mime_type(value)

    if not utils.contains(allowed_types, file_type) then
        return false, utils.format_error("ImageField:validate", "invalid image type: " .. file_type)
    end

    return true, self.file
end

fields.BaseField = BaseField
fields.StringField = StringField
fields.IntField = IntField
fields.FloatField = FloatField
fields.BooleanField = BooleanField
fields.ListField = ListField
fields.TableField = TableField
fields.ReferenceField = ReferenceField
fields.EmbeddedDocumentField = EmbeddedDocumentField
fields.FileField = FileField
fields.ImageField = ImageField

return fields
