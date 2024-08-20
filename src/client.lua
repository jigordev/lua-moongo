local mongo = require("mongo")
local checkargs = require("checkargs")
local class = require("middleclass")
local utils = require("moongo.utils")

local MongoClient = class("MongoClient")

function MongoClient:initialize(db_name, host, port, username, password)
    checkargs.check_arg("MongoClient:new", "db_name", { "string" }, db_name, true)
    checkargs.check_arg("MongoClient:new", "host", { "string" }, host, true)
    checkargs.check_arg("MongoClient:new", "port", { "number" }, port, true)
    checkargs.check_arg("MongoClient:new", "username", { "string" }, username, true)
    checkargs.check_arg("MongoClient:new", "password", { "string" }, password, true)

    self.db_name = db_name
    self.host = host or "localhost"
    self.port = port or 27017
    self.username = username
    self.password = password

    self:connect(self.host, self.port, self.username, self.password)
    if self.db_name ~= nil then
        self.db = self:get_db(self.db_name)
    end
end

function MongoClient:connect(host, port, username, password)
    checkargs.check_arg("MongoClient:connect", "host", { "string" }, host)
    checkargs.check_arg("MongoClient:connect", "port", { "number" }, port)
    checkargs.check_arg("MongoClient:connect", "username", { "string" }, username, true)
    checkargs.check_arg("MongoClient:connect", "password", { "string" }, password, true)

    local auth_string = username and password and (username .. ":" .. password .. "@") or ""
    local uri = host .. ":" .. port

    local success, result = pcall(function()
        return mongo.Client("mongodb://" .. auth_string .. uri)
    end)

    if not success then
        error(utils.format_error("MongoClient:connect", "Database connection failed: " .. result))
    end

    self.client = result

    return result
end

function MongoClient:get_client()
    return self.client
end

function MongoClient:get_db(db_name)
    checkargs.check_arg("MongoClient:get_db", "db_name", { "string" }, db_name)
    return self.client:getDatabase(db_name)
end

function MongoClient:execute(command, options, prefs)
    checkargs.check_arg("MongoClient:execute", "command", { "table" }, command)
    checkargs.check_arg("MongoClient:execute", "options", { "table" }, options, true)
    checkargs.check_arg("MongoClient:execute", "prefs", { "table" }, options, true)
    return self.client:command(self.db_name, command, options, prefs)
end

function MongoClient:get_gridfs(prefix)
    checkargs.check_arg("MongoClient:get_gridfs", "prefix", { "string" }, prefix, true)
    return self.client:getGridFS(self.db_name, prefix)
end

function MongoClient:get_read_prefs()
    return self.db:getReadPrefs()
end

function MongoClient:set_read_prefs(...)
    local prefs = mongo.ReadPrefs(...)
    return self.db:setReadPrefs(prefs)
end

return MongoClient
