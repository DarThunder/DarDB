local codec = {}

function codec.serialize(t, field)
    local indent = ""
    local result = "{\n"

    local keys = field or {}
    local is_field_mode = #keys > 0

    if not is_field_mode then
        for k in pairs(t) do
            table.insert(keys, k)
        end
    end

    for _, key in ipairs(keys) do
        local value = t[key]
        local value_str

        if type(value) == "string" then
            value_str = '"' .. value .. '"'
        elseif type(value) == "table" then
            value_str = codec.serialize(value)
        else
            value_str = tostring(value)
        end

        result = result .. indent .. "  " .. key .. " = " .. value_str .. ",\n"
    end

    if result:sub(-2) == ",\n" then
        result = result:sub(1, -3) .. "\n"
    end

    result = result .. indent .. "}"
    return result
end


function codec.deserialize(str)
    local func = load("return " .. str)
    if not func then return end
    return func()
end

function codec.parseMetadata(IObject)
  --local ogPos = IObject.file:seek("cur")
  IObject.file:seek("set", 0)
  local metadata = {"patterns", "fields", "osr"}

  for i = 1, #metadata do
    local buffer = {}

    local key = metadata[i]

    while true do
      local byteRead = IObject.file:read(1)
      if not byteRead or byteRead == "\0" then break end
      table.insert(buffer, byteRead)
    end

    local rawString = table.concat(buffer)
    local values = {}

    for value in string.gmatch(rawString, "([^,]+)") do
      table.insert(values, value)
    end

    if key == "osr" then
      IObject[key] = tonumber(values[1])
    else
      IObject[key] = values
    end
  end
  IObject["offset"] = IObject.file:seek("cur")

  --IObject.file:seek("set", ogPos)
end

return codec
