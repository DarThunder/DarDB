local node = require("src.structures.b_tree_node")

local bTree = {}

local function splitChild(parentNode, childIndex)
  local leftNode, promotedRecord, rightNode = parentNode.children[childIndex]:split()

  parentNode:addRecord(promotedRecord)
  parentNode.children[childIndex] = leftNode
  table.insert(parentNode.children, childIndex + 1, rightNode)
end

local function insertInNode(self, root, record)
  if root:getStatus() == "leaf" or #root.children == 0 then
    root:addRecord(record)
  else
    local childIndex = root:getChild(record.key)
    local childNode = root.children[childIndex]

    insertInNode(self, childNode, record)

    if #childNode.records > self.maxKeys then
      splitChild(root, childIndex)
    end
  end
end

local function splitRoot(self)
  local leftNode, promotedRecord, rightNode = self.root:split()

  self.root = node.new(promotedRecord, {leftNode, rightNode}, "root")
end

function bTree:insert(record)
  insertInNode(self, self.root, record)

  if #self.root.records > self.maxKeys then
    splitRoot(self)
  end
end

local function getPredecessor(root)
  while root:getStatus() ~= "leaf" do
    root = root.children[#root.children]
  end
  return root.records[#root.records]
end

local function getSuccessor(root)
  while root:getStatus() ~= "leaf" do
    root = root.children[1]
  end
  return root.records[1]
end

local function mergeChildren(parent, index)
  local child = parent.children[index]
  local sibling = parent.children[index + 1]

  table.insert(child.records, parent.records[index])
  for _, r in ipairs(sibling.records) do
    table.insert(child.records, r)
  end
  for _, c in ipairs(sibling.children or {}) do
    table.insert(child.children, c)
  end

  table.remove(parent.records, index)
  table.remove(parent.children, index + 1)
end

local function fixChild(self, parent, index)
  local t = math.floor(self.maxKeys / 2) + 1
  local child = parent.children[index]

  local left = parent.children[index - 1]
  local right = parent.children[index + 1]

  if left and #left.records >= t then
    table.insert(child.records, 1, parent.records[index - 1])
    parent.records[index - 1] = table.remove(left.records)
    if #left.children > 0 then
      table.insert(child.children, 1, table.remove(left.children))
    end

  elseif right and #right.records >= t then
    table.insert(child.records, parent.records[index])
    parent.records[index] = table.remove(right.records, 1)
    if #right.children > 0 then
      table.insert(child.children, table.remove(right.children, 1))
    end

  else
    if left then
      mergeChildren(parent, index - 1)
    else
      mergeChildren(parent, index)
    end
  end
end

function bTree:remove(root, key)
  local t = math.floor(self.maxKeys / 2) + 1

  local i = 1
  while i <= #root.records and key > root.records[i].key do
    i = i + 1
  end

  if i <= #root.records and key == root.records[i].key then
    if root:getStatus() == "leaf" then
      table.remove(root.records, i)
      return true
    else
      local left = root.children[i]
      local right = root.children[i + 1]

      if #left.records >= t then
        local pred = getPredecessor(left)
        root.records[i] = pred
        self:remove(left, pred.key)
      elseif #right.records >= t then
        local succ = getSuccessor(right)
        root.records[i] = succ
        self:remove(right, succ.key)
      else
        mergeChildren(root, i)
        self:remove(left, key)
      end
    end
  else
    local child = root.children[i]

    if not child then return end

    if #child.records < t then
      fixChild(self, root, i)
      child = root.children[i]
    end

    self:remove(child, key)
  end
end

function bTree:search(root, key)
  for i, record in ipairs(root.records) do
    if key == record.key then
      return record
    elseif key < record.key then
      if root:getStatus() == "leaf" then return nil end
      return self:search(root.children[i], key)
    end
  end

  if root:getStatus() == "leaf" then return nil end
  return self:search(root.children[#root.records + 1], key)
end

return {
  new = function (record)
    if type(record) ~= "table" or not record.key then return nil end

    local self = {
      root = node.new(record, nil, "root"),
      maxKeys = 5
    }
    setmetatable(self, {__index = bTree})
    return self
  end
}
