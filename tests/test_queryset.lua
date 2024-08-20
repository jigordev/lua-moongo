local class = require("middleclass")
local moongo = require("moongo")

local function create_document()
    local client = moongo.MongoClient:new("test_db")
    local Document = class("Document", moongo.Document)
    Document:set_config({ database = client.db, collection = "test" })
    Document:set_fields({
        name = moongo.fields.StringField(),
        age = moongo.fields.IntField()
    })
    return Document
end

local function test_queryset_initialization()
    local document = create_document()
    local queryset = document.objects
    assert(queryset.document == document, "Failed to initialize QuerySet with document")
    assert(queryset.collection ~= nil, "Failed to initialize QuerySet with collection")
    assert(next(queryset.query) == nil, "QuerySet query should be empty on initialization")
end

local function test_queryset_filter()
    local document = create_document()
    local queryset = document.objects
    local filter = { age = { ["$gt"] = 25 } }
    queryset:filter(filter)
    assert(queryset.query.age["$gt"] == 25, "Failed to set query filter")
end

local function test_queryset_paginate()
    local document = create_document()
    local queryset = document.objects
    queryset:paginate(2, 10)
    assert(queryset.current_page == 2, "Failed to set current page")
    assert(queryset.page_size == 10, "Failed to set page size")
    assert(queryset.options.skip == 10, "Failed to set skip option for pagination")
    assert(queryset.options.limit == 10, "Failed to set limit option for pagination")
end

local function test_queryset_get()
    local document = create_document()
    local queryset = document.objects
    queryset:filter({ name = "Moongo" })
    local result = queryset:get()
    assert(result.name == "Moongo", "Failed to get the correct document")
end

local function test_queryset_all()
    local document = create_document()
    local queryset = document.objects
    local results = queryset:all()
    assert(#results >= 1, "Failed to get all documents")
    assert(results[1].name == "Moongo", "Failed to get the correct documents")
end

local function test_queryset_first()
    local document = create_document()
    local queryset = document.objects
    local result = queryset:first()
    assert(result.name == "Moongo", "Failed to get the first document")
end

local function test_queryset_exclude()
    local document = create_document()
    local queryset = document.objects
    queryset:filter({ age = { ["$gt"] = 25 } }):exclude({ name = "Excluded Document" })
    assert(queryset.query["$and"][1].age["$gt"] == 25, "Failed to set filter in exclude")
    assert(queryset.query["$and"][2]["$nor"][1].name == "Excluded Document", "Failed to set exclude filter")
end

local function test_queryset_only()
    local document = create_document()
    local queryset = document.objects
    queryset:only("name", "age")
    assert(queryset.options.projection.name == 1, "Failed to set only projection for name")
    assert(queryset.options.projection.age == 1, "Failed to set only projection for age")
end

local function test_queryset_search_text()
    local document = create_document()
    local queryset = document.objects
    queryset:search_text("test query")
    assert(queryset.options["$text"]["$search"] == "test query", "Failed to set search text option")
end

local function test_queryset_order_by()
    local document = create_document()
    local queryset = document.objects
    queryset:order_by("age", -1)
    assert(queryset.options.sort.age == -1, "Failed to set order by option")
end

local function test_queryset_limit()
    local document = create_document()
    local queryset = document.objects
    queryset:limit(5)
    assert(queryset.options.limit == 5, "Failed to set limit option")
end

local function test_queryset_delete()
    local document = create_document()
    local queryset = document.objects
    queryset.collection:insertOne({ name = "Delete", age = 20 })
    queryset:filter({ name = "Delete" })
    local deleted = queryset:delete()
    assert(deleted, "Failed to delete documents")
end

local function test_queryset_count()
    local document = create_document()
    local queryset = document.objects
    local count = queryset:count()
    assert(count >= 1, "Failed to count documents")
end

local function test_queryset_exists()
    local document = create_document()
    local queryset = document.objects
    local exists = queryset:exists()
    assert(exists, "Failed to check if documents exist")
end

local function test_queryset_aggregate()
    local document = create_document()
    local queryset = document.objects
    local pipeline = '[ { "$group": { "_id": "$name" } } ]'
    local results = queryset:aggregate(pipeline)
    assert(#results >= 1, "Failed to aggregate documents")
    assert(results[1]._id == "Moongo", "Failed to aggregate the correct documents")
end

local function test_queryset_skip()
    local document = create_document()
    local queryset = document.objects
    queryset:skip(5)
    assert(queryset.options.skip == 5, "Failed to set skip option")
end

local function test_queryset_insert()
    local document = create_document()
    local queryset = document.objects
    local result = queryset:insert({ name = "New Document" })
    assert(result, "Failed to insert documents")
end

local function test_queryset_update()
    local document = create_document()
    local queryset = document.objects
    local filter = { name = "Moongo" }
    local update_fields = { age = 31 }
    local updated = queryset:update(filter, update_fields)
    assert(updated, "Failed to update documents")
end

local function test_queryset_update_one()
    local document = create_document()
    local queryset = document.objects
    local filter = { name = "Moongo" }
    local update_fields = { age = 32 }
    local updated = queryset:update_one(filter, update_fields)
    assert(updated, "Failed to update one document")
end

local function runtests()
    test_queryset_initialization()
    test_queryset_filter()
    test_queryset_paginate()
    test_queryset_get()
    test_queryset_all()
    test_queryset_first()
    test_queryset_exclude()
    test_queryset_only()
    test_queryset_search_text()
    test_queryset_order_by()
    test_queryset_limit()
    test_queryset_delete()
    test_queryset_count()
    test_queryset_exists()
    test_queryset_aggregate()
    test_queryset_skip()
    test_queryset_insert()
    test_queryset_update()
    test_queryset_update_one()
    print("All tests passed successfully!")
end

runtests()
