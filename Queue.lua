--queue has been used to BFS algoritm

Queue = {}
Queue.__index = Queue

function Queue.new()
    return setmetatable({first=0, last=-1}, Queue)
end

function Queue.isEmpty(queue)
    if queue.first > queue.last then return true
    else return false end
end

function Queue.push(queue, val)
    queue.last = queue.last + 1
    queue[queue.last] = val
end

function Queue.pop(queue)
    local val = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return val
end

return Queue