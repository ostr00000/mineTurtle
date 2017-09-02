--required modules: Cords, Heap
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

-- knownMaterials = { material , "void" , "checked" , "secured" }
function Space:update(cords, val, state)
    local x, y, z = cords:unpack()
    local dim = self.dim
    if dim[x] == nil then dim[x] = {} end
    if dim[x][y] == nil then dim[x][y] = {} end
    
    if state then
        if val == state.config.material then 
            if dim[x][y][z] ~= val then --first time apperar
                state.numMaterials = state.numMaterials + 1 
            end
        elseif val == "void" then --material will be mined
            state.numMaterials = state.numMaterials - 1
            state.collectedResources = state.collectedResources + 1
        elseif val ~= "checked" and val ~= "secured" and val ~= nil then 
            print("ERROR: unknown material") 
        end
    end
    dim[x][y][z] = val
end

function Space:initBase(baseRadius, state)
	local length = baseRadius - 1
	for i = -length, length do
		for j = -length, length do
			for k = -length, length do
				Space.update(self, Cords.new(i, j, k), "secured", state)
			end
		end
	end
	for i = 0, length do Space.update(self, Cords.new(i, 0, 0), "checked", state) end
end

function Space:findNearestMaterial(cord, searchMaterial)
    local stopCondition = function(material, _) return material == searchMaterial end
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
    local delta = to - from
    local length = delta:length()
    local dif = delta / length
    local i, dest = 1, from
    repeat
        dest = (dif * i + from):round()
        i = i + 1
    until self:getMaterial(dest) ~= "secured" and dest ~= from
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
    function Data.new(fdir, cords)
        local dis = targetPosition:distance(cords) + cord:distance(cords)
        return setmetatable({
                firstDirection=fdir, 
                position=cords,
                distance=dis}, Data) 
    end
    function Data:__tostring()
        return --"[firstDir:"..(self.firstDirection or 0)
               "[".." position:"..tostring(self.position)
               .."distance:"..self.distance.."]"
    end
    setmetatable(Data, {__call = function(_, ...)return Data.new(...)end})
    
    local heap = Heap.new(function(a,b)return a.distance > b.distance end)

    local add = function(fdir, cord)
        if not self.bfs:getMaterial(cord) then
            heap:insert(Data(fdir,cord))
            self.bfs:update(cord, true)
        end
    end

    add("x+", cord + Cords(1, 0, 0))
    add("x-", cord + Cords(-1,0, 0))
    add("y+", cord + Cords(0, 1, 0))
    add("y-", cord + Cords(0,-1, 0))
    add("z+", cord + Cords(0, 0, 1))
    add("z-", cord + Cords(0, 0,-1))
    while true do
        local data = heap:deleteRoot()
        local position, fdir = data.position, data.firstDirection
        local mat = self:getMaterial(position)
        
        if stopCondition(mat, position) then
            self.bfs = nil
            return position, fdir
		    end

		    if mat ~= "secured" then
      			add(fdir, position + Cords(1, 0, 0))
            add(fdir, position + Cords(-1,0, 0))
            add(fdir, position + Cords(0, 1, 0))
            add(fdir, position + Cords(0,-1, 0))
            add(fdir, position + Cords(0, 0, 1))
            add(fdir, position + Cords(0, 0,-1))
  		  end
    end
end

return Space
