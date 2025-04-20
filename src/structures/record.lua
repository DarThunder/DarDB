--test path
local sha = require("src.sha")
--local sha = require("idar-cl.sha")

local record = {}

local function normalizeKey(key)
  key = tostring(key)
  if not key then return nil end
  return sha.sha256(key)
end

function record:new(key, bytePos)
  local newRecord = {key = normalizeKey(key), byte_pos = bytePos}
  setmetatable(newRecord, {__index = self})

  return newRecord
end

function record:getKey()
  return self.key
end

function record:setBytePos(newBytePos)
  self.byte_pos = newBytePos
end

function record:getBytePos()
  return self.byte_pos
end

return {
  new = function (key, bytePos)
    if type(bytePos) ~= "number" or #tostring(key) == 64 then return nil end

    return record:new(key, bytePos)
  end,
  normalizeKey = function (key)
    return normalizeKey(key)
  end
}
