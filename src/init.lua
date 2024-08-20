local MongoClient = require("moongo.client")
local Document = require("moongo.document").Document
local EmbeddedDocument = require("moongo.document").EmbeddedDocument
local fields = require("moongo.fields")

local moongo = {}

moongo.MongoClient = MongoClient
moongo.Document = Document
moongo.EmbeddedDocument = EmbeddedDocument
moongo.fields = fields

return moongo
