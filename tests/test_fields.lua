local fields = require("moongo.fields")

local function test_BaseField()
    local function test_1()
        local field = fields.BaseField:new()
        assert(field:validate("test", "value"))
    end

    local function test_2()
        local field = fields.BaseField:new({ required = true })
        local status, err = field:validate("test", nil)
        assert(not status and string.match(err, "field test is required"))
    end

    return { test_1, test_2 }
end

local function test_StringField()
    local function test_1()
        local field = fields.StringField:new()
        assert(field:validate("test", "value"))
    end

    local function test_2()
        local field = fields.StringField:new({ required = true, min_length = 3, max_length = 5 })
        local status, err = field:validate("test", "va")
        assert(not status and string.match(err, "shorter than minimum length"))
        status, err = field:validate("test", "valuetoolong")
        assert(not status and string.match(err, "exceeds maximum length"))
    end

    return { test_1, test_2 }
end

local function test_IntField()
    local function test_1()
        local field = fields.IntField:new()
        assert(field:validate("test", 42))
    end

    local function test_2()
        local field = fields.IntField:new({ min_value = 10, max_value = 50 })
        local status, err = field:validate("test", 5)
        assert(not status and string.match(err, "less than minimum value"))
        status, err = field:validate("test", 55)
        assert(not status and string.match(err, "exceeds maximum value"))
    end

    return { test_1, test_2 }
end

local function test_FloatField()
    local function test_1()
        local field = fields.FloatField:new()
        assert(field:validate("test", 3.14))
    end

    local function test_2()
        local field = fields.FloatField:new({ min_value = 1.0, max_value = 5.0 })
        local status, err = field:validate("test", 0.5)
        assert(not status and string.match(err, "less than minimum value"))
        status, err = field:validate("test", 5.5)
        assert(not status and string.match(err, "exceeds maximum value"))
    end

    return { test_1, test_2 }
end

local function test_BooleanField()
    local function test_1()
        local field = fields.BooleanField:new()
        assert(field:validate("test", true))
    end

    local function test_2()
        local field = fields.BooleanField:new()
        local status, err = field:validate("test", "not_boolean")
        assert(not status and string.match(err, "must be a boolean"))
    end

    return { test_1, test_2 }
end

local function test_ListField()
    local function test_1()
        local field = fields.ListField:new()
        assert(field:validate("test", { "item1", "item2" }))
    end

    local function test_2()
        local field = fields.ListField:new({ min_length = 2, max_length = 4 })
        local status, err = field:validate("test", { "item1" })
        assert(not status and string.match(err, "length is less than the minimum required"))
        status, err = field:validate("test", { "item1", "item2", "item3", "item4", "item5" })
        assert(not status and string.match(err, "length exceeds the maximum allowed"))
    end

    return { test_1, test_2 }
end

local function test_TableField()
    local function test_1()
        local field = fields.TableField:new()
        assert(field:validate("test", { key = "value" }))
    end

    local function test_2()
        local field = fields.TableField:new({ schema = { key = { type = "string" } } })
        local status, err = field:validate("test", { key = 123 })
        assert(not status and string.match(err, "table does not match the schema"))
    end

    return { test_1, test_2 }
end

local function test_ReferenceField()
    local function test_1()
        local field = fields.ReferenceField:new()
        assert(field:validate("test", { _id = "123" }))
    end

    local function test_2()
        local field = fields.ReferenceField:new()
        local status, err = field:validate("test", "not_a_table")
        assert(not status and string.match(err, "the reference is not a valid document"))
    end

    return { test_1, test_2 }
end

local function test_EmbeddedDocumentField()
    local function test_1()
        local embedded_doc = require("moongo.document").EmbeddedDocument:new({ key = fields.StringField:new() })
        local field = fields.EmbeddedDocumentField:new(embedded_doc)
        assert(field:validate("test", { key = "value" }))
    end

    local function test_2()
        local embedded_doc = require("moongo.document").EmbeddedDocument:new({ key = fields.StringField:new() })
        local field = fields.EmbeddedDocumentField:new(embedded_doc)
        local status, err = field:validate("test", "not_a_table")
        assert(not status and string.match(err, "the reference is not a valid embedded document"))
    end

    return { test_1, test_2 }
end

local function gridfs_mock()
    local file = {
        write = function(...)
            return true
        end,
    }

    local gridfs = {
        createFile = function(...)
            return file
        end,
    }

    return gridfs
end

local function test_FileField()
    local function test_1()
        local gridfs = gridfs_mock()
        local field = fields.FileField:new(gridfs)
        assert(field:validate("test", "file_path"))
    end

    local function test_2()
        local gridfs = gridfs_mock()
        local field = fields.FileField:new(gridfs)
        local status, err = field:validate("test", 123)
        assert(not status and string.match(err, "must be a string %(file content%)"))
    end

    return { test_1, test_2 }
end

local function test_ImageField()
    local function test_1()
        local gridfs = gridfs_mock()
        local field = fields.ImageField:new(gridfs, { allowed_types = { "image/png" } })
        assert(field:validate("test", "image.png"))
    end

    local function test_2()
        local gridfs = gridfs_mock()
        local field = fields.ImageField:new(gridfs, { allowed_types = { "image/png" } })
        local status, err = field:validate("test", "image.jpg")
        assert(not status and string.match(err, "invalid image type"))
    end

    return { test_1, test_2 }
end

local function run_tests()
    local test_functions = {
        test_BaseField,
        test_StringField,
        test_IntField,
        test_FloatField,
        test_BooleanField,
        test_ListField,
        test_TableField,
        test_ReferenceField,
        test_EmbeddedDocumentField,
        test_FileField,
        test_ImageField
    }

    for _, test_function in ipairs(test_functions) do
        local tests = test_function()
        for _, test in ipairs(tests) do
            test()
        end
    end

    print("All tests passed successfully!")
end

run_tests()
