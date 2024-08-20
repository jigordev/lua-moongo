local moongo = require("moongo")
local class = require("middleclass")
local fields = moongo.fields

local client = moongo.MongoClient:new("moongo")

local People = class("People", moongo.Document)
People:set_config({ database = client.db, collection = "people" })
People:set_fields({
	name = fields.StringField({ max_length = 30 }),
	age = fields.IntField()
})

local people = People:new({ name = "John", age = 30 })

print(people.name)
