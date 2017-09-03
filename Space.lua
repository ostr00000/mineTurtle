--required modules: Cords, Heap, TurtleUtils
-- Space represent searched block position and turtle current position

Space = {}
Space.__index = Space

function Space.new ()
    return setmetatable({dim={}}, Space) 
end

function Space:getMaterial(cords)
    if self.dim[cords.x] ~= nil and self.dim[cords.x][cords.y] ~= nil then
		return self.dim[cords.x][cords.y][cords.z]
	else return nil end
end

function Space:hasChecked(cords)
    return self:getMaterial(cords) == "checked"
end

local knownMaterials = setmetatable(
  {["checked"] = true, ["secured"] = true, [true] = true },
  {__index = function(_, val)return val == nil end})
  
function Space:update(cords, val)
    local x, y, z = cords:unpack()
    local dim = self.dim
    if dim[x] == nil then dim[x] = {} end
    if dim[x][y] == nil then dim[x][y] = {} end
    local firstTime = true
    
    if TurtleUtils.isAllowedMaterial(val) then 
        if dim[x][y][z] == val then
            firstTime = false
        end
    elseif not knownMaterials[val] then 
        print("ERROR: unknown material") 
    end
    dim[x][y][z] = val
    return firstTime
end

function Space:initBase(baseRadius, state)
	local length = baseRadius - 1
	for i = -length, length do
		for j = -length, length do
			for k = -length, length do
				Space.update(self, Cords.new(i, j, k), "secured")
			end
		end
	end
	for i = 0, length do Space.update(self, Cords.new(i, 0, 0), "checked") end
end

function Space:findNearestMaterial(cord)
    local stopCondition = function(material, _) 
        return TurtleUtils.isAllowedMaterial(material)
    end
    local position, _= self:BFS(cord, stopCondition)
    return position
end

local function decode(code)
    local char = string.sub(code, 1, 1)
    local sign = nil
    if string.sub(code, 2, 2) == "+" then sign = 1 else sign = -1 end

    if char == "x" then return Cords(sign, 0, 0)
    elseif char == "y" then return Cords(0, sign, 0)
    else return Cords(0, 0, sign) end
end

function Space:findPointInLine(from, to)
    local isInSec = TurtleUtils.isInSecureRange(to)

    local delta = to - from
    local length = delta:length()
    local dif = delta / length
    local i, dest = 1, from
    repeat
        dest = (dif * i + from):round()
        i = i + 1
    until self:getMaterial(dest) ~= "secured" and dest ~= from
          and (isInSec or not TurtleUtils.isInSecureRange(dest))
    return dest
end

function Space:findNearestPosition(cord, targetPosition)
     targetPosition = self:findPointInLine(cord, targetPosition)
     local stopCondition = function(_, position) return position == targetPosition end
     local position, firstDir =  self:BFS(cord, stopCondition, targetPosition)
     return cord + decode(firstDir)
end

function Space:BFS(cord, stopCondition, targetPosition)
    targetPosition = targetPosition or cord
    self.bfs = Space.new()
    local Data = {}
    Data.__index = Data
    function Data.new(fdir, cords, dis)
        dis = dis or -1
        return setmetatable({
                firstDirection=fdir, 
                position=cords,
                distance=dis+1}, Data) 
    end
    function Data:__tostring()
        return --"[firstDir:"..(self.firstDirection or 0)
               "[".." position:"..tostring(self.position)
               .."distance:"..self.distance.."]"
    end
    setmetatable(Data, {__call = function(_, ...)return Data.new(...)end})
    
    local heap = Heap.new(function(a,b)return a.distance > b.distance end)

    local add = function(fdir, cord, dis)
        if not self.bfs:getMaterial(cord) then
            heap:insert(Data(fdir,cord, dis))
            self.bfs:update(cord, true)
        end
    end

    self.bfs:update(cord, true)
    add("x+", cord + Cords(1, 0, 0))
    add("x-", cord + Cords(-1,0, 0))
    add("y+", cord + Cords(0, 1, 0))
    add("y-", cord + Cords(0,-1, 0))
    add("z+", cord + Cords(0, 0, 1))
    add("z-", cord + Cords(0, 0,-1))
    while true do
        local data = heap:deleteRoot()
        local position, fdir = data.position, data.firstDirection
        local mat, dis = self:getMaterial(position), data.distance
        if stopCondition(mat, position) then
            self.bfs = nil
            return position, fdir
		    end

		    if mat ~= "secured" then
      			add(fdir, position + Cords(1, 0, 0), dis)
            add(fdir, position + Cords(-1,0, 0), dis)
            add(fdir, position + Cords(0, 1, 0), dis)
            add(fdir, position + Cords(0,-1, 0), dis)
            add(fdir, position + Cords(0, 0, 1), dis)
            add(fdir, position + Cords(0, 0,-1), dis)
  		  end
    end
end

return Space
