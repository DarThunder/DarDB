local codec = require("src.storage.codec")

local dbio = {}

local openModeMap = {
  i = "r+b",
  r = "rb",
  u = "r+b",
  d = "r+b",
  g = "r+b"
}

local function createIObject(self, path, mode)
  local file = {}
  file.file = io.open(path, mode)

  if not file.file then error("File not found: " .. path) end
  setmetatable(file, { __index = self })

  return file
end

local function validateMode(self, allowedModes, operation)
  if not allowedModes[self.mode] then error("Cannot " .. operation .. " in current mode: " .. self.mode) end
end

function dbio:open(path, mode)
  local realMode = openModeMap[mode]
  if not realMode then error("Mode not supported: " .. tostring(mode)) end

  local newIObject = createIObject(self, path, realMode)
  codec.parseMetadata(newIObject)
  newIObject.mode = mode

  return newIObject
end

function dbio:insert(data)
  validateMode(self, { i = true, u = true }, "insert")

  if not data or type(data) ~= "table" then return nil end
  if not self.patterns or not self.fields then return nil end

  for i = 1, #self.fields do
    self.file:write(string.pack(self.patterns[i], data[self.fields[i]]))
  end

  return codec.serialize(data, self.fields)
end

function dbio:read(cli)
  validateMode(self, { i = true, r = true, u = true, d = true }, "read")

  if not (self.patterns and self.fields and self.osr) then return nil end

  local block = self.file:read(self.osr)
  if not block or #block < self.osr then return nil end

  local record = {}
  local offset = 1

  for i, pat in ipairs(self.patterns) do
    local value
    value, offset = string.unpack(pat, block, offset)

    local fieldName = self.fields[i]
    record[fieldName] = value
  end

  if cli then record = codec.serialize(record, self.fields) end

  return record
end

function dbio:update(newData)
  validateMode(self, { u = true }, "update")

  if type(newData) ~= "table" or not self.osr then return nil end

  local oldRecord = self:read()
  if not oldRecord or #oldRecord == 0 then return nil end

  for k, v in pairs(newData) do
    oldRecord[k] = v
  end

  self.file:seek("cur", -self.osr)

  return self:insert(oldRecord)
end

function dbio:delete()
  validateMode(self, { d = true }, "delete")

  if not self.osr then return nil end

  local old = self:read(true)
  if not old or old == "" then return nil end

  self.file:seek("cur", -self.osr)
  self.file:write(string.char(2))
  self.file:seek("cur", self.osr - 2)
  self.file:write(string.char(2))

  return old
end

return {open = function (path, mode) return dbio:open(path, mode) end}
