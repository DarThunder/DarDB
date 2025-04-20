local bTreeNode = {}

function bTreeNode:new(record, children, status)
  local newNode = {
    records = {record},
    children = children or {},
    status = status
  }
  setmetatable(newNode, {__index = self})
  return newNode
end

function bTreeNode:getSize()
  return #self.records
end

function bTreeNode:setStatus(newStatus)
  if newStatus == "root" or newStatus == "branch" or newStatus == "leaf" then
    self.status = newStatus
  else
    error("Invalid status")
  end
end

function bTreeNode:getStatus()
  return self.status
end

function bTreeNode:getChild(key)
  for i, record in ipairs(self.records) do
    if key < record.key then
      return i
    end
  end
  return #self.records + 1
end

function bTreeNode:addRecord(record)
  if type(record) ~= "table" or not record.key then return nil end
  table.insert(self.records, record)
  table.sort(self.records, function(a, b) return a.key < b.key end)
end

function bTreeNode:removeRecord(key)
  for i, r in ipairs(self.records) do
    if r.key == key then
      table.remove(self.records, i)
      return #self.records
    end
  end
  return nil
end

function bTreeNode:split()
  local middleIndex = math.floor(#self.records / 2) + 1
  local promotedRecord = self.records[middleIndex]

  local leftNode = {
    records = {},
    children = {},
    status = self.status
  }
  setmetatable(leftNode, {__index = self})

  local rightNode = {
    records = {},
    children = {},
    status = self.status
  }
  setmetatable(rightNode, {__index = self})

  for i, record in ipairs(self.records) do
    if i < middleIndex then
      table.insert(leftNode.records, record)
    elseif i > middleIndex then
      table.insert(rightNode.records, record)
    end
  end

  if self.children and #self.children > 0 then
    for i, child in ipairs(self.children) do
      if i <= middleIndex then
        table.insert(leftNode.children, child)
      else
        table.insert(rightNode.children, child)
      end
    end
    leftNode.status = "branch"
    rightNode.status = "branch"
  else
    leftNode.status = "leaf"
    rightNode.status = "leaf"
  end

  return leftNode, promotedRecord, rightNode
end

return {
  new = function (record, children, status)
    if not (status == "root" or status == "branch" or status == "leaf") then return nil end
    if type(record) ~= "table" or not record.key then return nil end
    return bTreeNode:new(record, children, status)
  end
}

