local utils = require("moongo.utils")

local function test_contains()
    local tbl = { 1, 2, 3, 4, 5 }
    assert(utils.contains(tbl, 3), "Failed to find existing value in table")
    assert(not utils.contains(tbl, 6), "Incorrectly found non-existing value in table")
end

local function test_format_error()
    local error_message = utils.format_error("test_function", "test_message")
    assert(error_message == "Error in test_function: test_message", "Incorrect error message format")
end

local function test_trim()
    local trimmed = utils.trim("   test   ")
    assert(trimmed == "test", "Failed to trim string correctly")
end

local function test_is_list()
    local tbl1 = { 1, 2, 3 }
    local tbl2 = { a = 1, b = 2 }
    local tbl3 = {}

    assert(utils.is_list(tbl1), "Failed to recognize list")
    assert(not utils.is_list(tbl2), "Incorrectly recognized table as list")
    assert(utils.is_list(tbl3), "Failed to recognize empty table as list")
end

local mock_mimetypes = {
    guess = function(file_data)
        return "text/plain"
    end
}
package.preload["mimeytypes"] = function()
    return mock_mimetypes
end

local function test_get_file_mime_type()
    local mime_type = utils.get_file_mime_type("test_file_data")
    assert(mime_type == "text/plain", "Failed to get correct mime type")
end

local function runtests()
    test_contains()
    test_format_error()
    test_trim()
    test_is_list()
    test_get_file_mime_type()
    print("All tests passed successfully!")
end

runtests()
