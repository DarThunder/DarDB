local record = require("src.structures.record")

local index = {}

function index:insert(key, bytePos)
  local newRec = record.new(key, bytePos)
  self.tree:insert(self.tree.root, newRec)
end

function index:search(key)
  key = record.normalizeKey(key)
  return self.tree:search(self.tree.root, key)
end

function index:rangeSearch(keys)
  if type(keys) ~= "table" then return nil end

  local records = {}
  for _, key in ipairs(keys) do
    local searchRecord = self:search(key)
    if searchRecord and type(searchRecord) == "table" then table.insert(records, searchRecord) end
  end

  return records
end

function index:update(oldKey, newKey, newBytePos)
  self:remove(oldKey)
  if oldKey == newKey then newKey = oldKey end
  self:insert(newKey, newBytePos)
end

function index:remove(key)
  key = record.normalize(key)
  self.tree:remove(self.tree.root, key)
end

return {
  attach = function (newBTree)
    if type(newBTree) ~= "table" or not newBTree.root or not newBTree.maxKeys then return nil end

    local self = {
      tree = newBTree,
    }
    setmetatable(self, {__index = index})

    return self
  end
}
