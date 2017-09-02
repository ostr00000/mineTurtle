
Heap = {}
Heap.__index = Heap

function Heap.new(order, arr)
    order = order or function(a, b) return a.key < b.key end
    local last
    if arr ~= nil then last=table.getn(arr) else last = 0 end
    arr = arr or {}
    return setmetatable({order=order, last=last, arr=arr}, Heap)
end

function Heap:insert(val)
    self.last = self.last + 1
    self.arr[self.last] = val
    local cur = self.last
    while cur ~= 1 do
        local parent = math.floor(cur / 2)
        if self.order(self.arr[parent], self.arr[cur]) then 
            self:swap(parent, cur)
            cur = math.floor(cur / 2)
        else break end
    end
end

function Heap:swap(a, b)
    local tmp = self.arr[a]
    self.arr[a] = self.arr[b]
    self.arr[b] = tmp  
end

function Heap:downheap(cur, maxindex)
    maxindex = maxindex or self.last
    local left = function() return cur * 2 end
    local right = function() return cur * 2 + 1 end
    while left() <= maxindex do
        if right() <= maxindex and self.order(self.arr[cur], self.arr[right()]) then
            if self.order(self.arr[left()], self.arr[right()]) then
                self:swap(right(), cur)
                cur = right()
            else 
                self:swap(left(), cur)
                cur = left()    
            end
        elseif self.order(self.arr[cur], self.arr[left()]) then 
            self:swap(left(), cur)
            cur = left()
        else break end
    end
end

function Heap:deleteRoot()
    assert(self.last > 0)
    local ret = self.arr[1]
    self.arr[1] = self.arr[self.last]
    self.arr[self.last] = nil
    self.last = self.last - 1
    self:downheap(1)
    return ret
end

function Heap:sort()
    for i=math.floor(self.last/2), 1, -1 do 
        self:downheap(i) 
    end
    for i=self.last, 2, -1 do
        self:swap(1, i)
        self:downheap(1, i - 1)
    end
end

function Heap:__tostring()
    local str = "last index:"..self.last.." vals:"
    for k, v in pairs(self.arr) do
        str = str..", ["..k.."]={"..tostring(v).."} "
    end
    return str
end

return Heap
