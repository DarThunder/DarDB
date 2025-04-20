local dbio = require "src.core.dbio"

local pagemgr = {}
local pageSize = 8192 --i will remove this and use the .yaml config file, someday
local pageOffset = 2

local function ihaveafile(self)
  return self.file and self.file.seek and self.pagesNo and self.rpp and true or false
end

function pagemgr:attach(path, pages)
  if ihaveafile(self) then return nil end

  if type(path) ~= "string" then return nil end
  local IObject = dbio.open(path, "g")
  if not IObject then return nil end

  for key, value in pairs(IObject) do
    self[key] = value
  end

  self.rpp = math.floor((pageSize - pageOffset) / self.osr)
  self.pagesNo = pages
end

function pagemgr:dettach()
  if ihaveafile(self) then
    self.file:close()
    self.file = nil
    self.pagesNo = nil
    self.rpp = nil
  end
end

function pagemgr:updateMetadata(records, page)
  if not ihaveafile(self) then return nil end
  if type(records) ~= "number" then return nil end

  self.file:seek("set", pageSize * (page - 1) + self.offset)

  local curRecords = string.unpack("I2", self.file:read(2))
  records = curRecords + records

  self.file:seek("cur", -pageOffset)
  self.file:write(string.pack("I2", records))

  return true
end

function pagemgr:getMetadata(page)
  if not ihaveafile(self) then return nil end
  if type(page) ~= "number" then return end

  self.file:seek("set", pageSize * (page - 1) + self.offset)
  local curRecords = string.unpack("I2", self.file:read(pageOffset))

  return curRecords
end

function pagemgr:createPage()
  if not ihaveafile(self) then return nil end

  self.file:seek("end")
  self.file:write(string.pack("I2", 0))
  local newPageOffset = self.file:seek("cur")
  self.file:write(string.rep("\1", pageSize - pageOffset))
  return newPageOffset
end

function pagemgr:seekFreeSpace()
  if not ihaveafile(self) then return nil end

  local curPage = self.pagesNo
  local records = self:getMetadata(self.pagesNo)
  if records < self.rpp then
    return pageSize * (curPage - 1 + self.offset) + pageOffset + self.osr * records, curPage
  else
    return self:createPage(), curPage + 1
  end
end
--[[ terminate this
function pagemgr:compactPage()
  if not ihaveafile(self) then return nil end

  local curPage = 1
  local dataOffset = self.offset + pageOffset

  while true do
    local pageStart = dataOffset + (pageSize * (curPage - 1))
    self.file:seek("set", pageStart)

    for _ = 1, self.rpp do
      local recordStart = self.file:seek("cur")
      local firstByte = self.file:read(1)
      if not firstByte then return string.char(3) end

      if firstByte == "\2" then
        self.file:seek("cur", self.osr - 2)
        local lastByte = self.file:read(1)
        if not lastByte then return string.char(3) end

        if lastByte == "\2" then
          return recordStart
        end
      end

      self.file:seek("set", recordStart + self.osr)
    end

    curPage = curPage + 1
    self.file:seek("set", dataOffset + (pageSize * curPage))
    if not self.file:read(1) then break end
    self.file:seek("cur", -1)
  end
end]]

return pagemgr
