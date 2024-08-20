local mongo = require("mongo")
local class = require("middleclass")
local QuerySet = require("moongo.queryset")
local BaseField = require("moongo.fields").BaseField
local documents = require("moongo.document")

local function get_config()
    return {
        database = mongo.Client("mongodb://localhost:27017"):getDatabase("test_db"),
        collection = "test_collection",
        queryset = QuerySet,
        indexes = {},
    }
end

local function test_embedded_document_initialize()
    local fields = {
        name = BaseField:new(),
        age = BaseField:new()
    }
    local embedded_doc = documents.EmbeddedDocument:new(fields)
    assert(embedded_doc.fields.name ~= nil, "Initialization: Field 'name' should be present")
    assert(embedded_doc.fields.age ~= nil, "Initialization: Field 'age' should be present")
end

local function test_embedded_document_call()
    local fields = {
        name = BaseField:new(),
        age = BaseField:new()
    }
    local embedded_doc = documents.EmbeddedDocument:new(fields)
    local values = { name = "John Doe", age = 30 }
    embedded_doc(values)
    assert(embedded_doc.values.name == "John Doe", "Call: Value for 'name' should be 'John Doe'")
    assert(embedded_doc.values.age == 30, "Call: Value for 'age' should be 30")
end

local function test_document_static()
    local config = get_config()
    local DocumentClass = class("TestDocument", documents.Document)
    DocumentClass:set_config(config)
    assert(DocumentClass:get_database() ~= nil, "Static: Database not defined")
    assert(DocumentClass:get_collection() ~= nil, "Static: Collection not defined")
end

local function test_document_initialize()
    local fields = {
        name = BaseField:new(),
        age = BaseField:new()
    }
    local config = get_config()
    local DocumentClass = class("TestDocument", documents.Document)
    DocumentClass:set_config(config)
    DocumentClass:set_fields(fields)
    local values = { name = "John Doe", age = 30 }
    local doc = DocumentClass:new(values)
    assert(doc.values.name == "John Doe", "Initialization: Value for 'name' should be 'John Doe'")
    assert(doc.values.age == 30, "Initialization: Value for 'age' should be 30")
end

local function test_document_save()
    local fields = {
        name = BaseField:new(),
        age = BaseField:new()
    }
    local config = get_config()
    local DocumentClass = class("TestDocument", documents.Document)
    DocumentClass:set_config(config)
    DocumentClass:set_fields(fields)
    local values = { name = "John Doe", age = 30 }
    local doc = DocumentClass:new(values)
    doc:save()
    assert(doc.values._id ~= nil, "Save: Document should have an _id after save")
end

local function test_document_delete()
    local fields = {
        name = BaseField:new(),
        age = BaseField:new()
    }
    local config = get_config()
    local DocumentClass = class("TestDocument", documents.Document)
    DocumentClass:set_config(config)
    DocumentClass:set_fields(fields)
    local values = { name = "John Doe", age = 30 }
    local doc = DocumentClass:new(values)
    doc:save()
    doc:delete()
    assert(next(doc.values) == nil, "Delete: Document values should be empty after delete")
end

local function test_document_from_json()
    local fields = {
        name = BaseField:new(),
        age = BaseField:new()
    }
    local config = get_config()
    local DocumentClass = class("TestDocument", documents.Document)
    DocumentClass:set_config(config)
    DocumentClass:set_fields(fields)
    local json_data = '{"name": "Moongo", "age": 35}'
    local result = DocumentClass:from_json(json_data)
    assert(result.name == "Moongo", "From JSON: Invalid document")
end

local function runtests()
    test_embedded_document_initialize()
    test_embedded_document_call()
    test_document_static()
    test_document_initialize()
    test_document_save()
    test_document_delete()
    test_document_from_json()
    print("All tests passed successfully!")
end

runtests()
