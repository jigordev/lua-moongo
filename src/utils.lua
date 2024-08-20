local utils = {}

function utils.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function utils.format_error(func_name, message)
    return string.format("Error in %s: %s", func_name, message)
end

function utils.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function utils.is_list(t)
    if type(t) ~= "table" then
        return false
    end

    if next(t) == nil then
        return true
    end

    local i = 0
    for k, _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end

    return true
end

function utils.get_file_mime_type(file_data)
    local mimetypes = require("mimetypes")
    return mimetypes.guess(file_data)
end

return utils
