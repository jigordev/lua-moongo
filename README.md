# Moongo

Moongo is an Object-Document Mapper for working with MongoDB in Lua.

## Usage

### Installation

You can install moongo using luarocks:

```sh
luarocks install lua-moongo
```

### Basic Usage

```lua
local class = require("middleclass")
local moongo = require("moongo")
local fields = require("moongo.fields")

local client = moongo.MongoClient:new("moongo_db")

local People = class("People", moongo.Document)
People:set_config({ database = client.db, collection = "people" })
People:set_fields({
	name = fields.StringField({max_length=30}),
	age = fields.IntField()
})

local people = People.objects:filter({name = "John"}):first()

if people then
	print(people.name)
end
```

## License

Moongo is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.