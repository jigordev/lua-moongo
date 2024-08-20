local mongo = require("mongo")
local MongoClient = require("moongo").MongoClient

local function test_initialize()
    local client = MongoClient:new("test_db", "localhost", 27017)
    assert("test_db" == client.db_name, "Initialization: Database name mismatch")
    assert("localhost" == client.host, "Initialization: Host mismatch")
    assert(27017 == client.port, "Initialization: Port mismatch")
    assert(client.client ~= nil, "Initialization: Client is nil")
    assert(client.db ~= nil, "Initialization: Database is nil")
end

local function test_connect()
    local client = MongoClient:new()
    local conn = client:connect("localhost", 27017)
    local db = client:get_db("test_db")
    assert(conn ~= nil, "Connection: Connection is nil")
    assert(db ~= nil, "Connection: Failed to get database")
end

local function test_execute()
    local client = MongoClient:new("test_db", "localhost", 27017)
    local result = client:execute({ ping = "" }):value()
    assert(result.ok == 1.0, "Execution: Ping command failed")
end

local function test_get_gridfs()
    local client = MongoClient:new("test_db", "localhost", 27017)
    local gridfs = client:get_gridfs("fs")
    assert(gridfs ~= nil, "Get GridFS: Failed to get fs")
end

local function test_get_set_read_prefs()
    local client = MongoClient:new("test_db", "localhost", 27017)
    client:set_read_prefs("primaryPreferred")
    local read_prefs = client:get_read_prefs()
    assert(mongo.type(read_prefs) == "mongo.ReadPrefs", "Read Preferences: Set and get mismatch")
end

local function runtests()
    test_initialize()
    test_connect()
    test_execute()
    test_get_gridfs()
    test_get_set_read_prefs()
    print("All tests passed successfully!")
end

runtests()
