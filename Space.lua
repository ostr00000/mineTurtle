--required modules: Cords, Heap
-- Space represent searched block position and turtle current position

Space = {}
Space.__index = Space

function Space.new ()
    local dim = {}
    dim[0] = {}
    dim[0][0] = {}
    dim[0][0][0] = "turtleHome"
    return setmetatable({dim=dim}, Space) 
end

function Space.getMaterial(space, cords)
    if space.dim[cords.x] ~= nil and space.dim[cords.x][cords.y] ~= nil then
		return space.dim[cords.x][cords.y][cords.z]
	else return nil end
end

function Space.hasChecked(space, cords)
    return Space.getMaterial(space, cords) == "checked"
end

-- knownMaterials = { material , "void" , "checked" , "secured" , "nearest" }
function Space.update(space, cords, val, state)
    local x, y, z = cords.x, cords.y, cords.z
    local dim = space.dim

    if dim[x] == nil then dim[x] = {} end
    if dim[x][y] == nil then dim[x][y] = {} end

    if val == state.config.material then 
        if dim[x][y][z] ~= val then --first time apperar
            state.numMaterials = state.numMaterials + 1 
        end
    elseif val == "void" then --material will be mined
        state.numMaterials = state.numMaterials - 1
        state.collectedResources = state.collectedResources + 1
    elseif val ~= "checked" and val ~= "secured" and val ~= "nearest" and val ~= nil then 
        print("ERROR: unknown material") 
    end
    dim[x][y][z] = val
end

function Space.initBase(space, baseRadius, state)
	local length = baseRadius - 1
	for i = -length, length do
		for j = -length, length do
			for k = -length, length do
				Space.update(space, Cords.new(i, j, k), "secured", state)
			end
		end
	end
	for i = 0, length do Space.update(space, Cords.new(i, 0, 0), "checked", state) end
end

function Space.findNearestMaterial(space, cord, searchMaterial)
    local Data = {}
    Data.__index = Data
    function Data.new(fdir, axis, dir, cords)
        return setmetatable({
                firstDirection=fdir, 
                axis=axis, 
                direction=dir, 
                position=cords,
                distance=cord:distance(cords)}, Data) 
    end
    function Data:__tostring()
        return --"[firstDir:"..(self.firstDirection or 0)
               --.." axis:"..self.axis 
               --.." direction:"..self.direction
               "[".." position:"..tostring(self.position)
               .."distance:"..self.distance.."]"
    end
    
    local heap = Heap.new(function(a,b)return a.distance > b.distance end)

    heap:insert(Data.new("x+", "x",  1, cord + Cords(1, 0, 0)))
    heap:insert(Data.new("x-", "x", -1, cord + Cords(-1,0, 0)))
    heap:insert(Data.new("y+", "y",  1, cord + Cords(0, 1, 0)))
    heap:insert(Data.new("y-", "y", -1, cord + Cords(0,-1, 0)))
    heap:insert(Data.new("z+", "z",  1, cord + Cords(0, 0, 1)))
    heap:insert(Data.new("z-", "z", -1, cord + Cords(0, 0,-1)))

    while true do
        local data = heap:deleteRoot()
        local axis, dir = data.axis, data.direction
        local position, fdir = data.position, data.firstDirection
        local mat = Space.getMaterial(space, position)
        
        if mat == searchMaterial then
            if searchMaterial == "nearest" then return data.firstDirection end
            return position
		    elseif mat ~= "secured" then

      			if axis == "x" then
      				heap:insert(Data.new(fdir, "x", dir, position + Cords(dir, 0, 0)))
      				heap:insert(Data.new(fdir, "y", 1,   position + Cords(0, 1, 0)))
      				heap:insert(Data.new(fdir, "y", -1,  position + Cords(0, -1, 0)))
      			elseif axis == "y" then
      				heap:insert(Data.new(fdir, "y", dir, position + Cords(0, dir, 0)))
      			end
      
      			if axis == "x" or axis == "y" then
      				heap:insert(Data.new(fdir, "z", 1,   position + Cords(0, 0, 1)))
      				heap:insert(Data.new(fdir, "z", -1,  position + Cords(0, 0, -1)))
      			else
      				heap:insert(Data.new(fdir, "z", dir, position + Cords(0, 0, dir)))
      			end
  		  end
    end
end

function Space.changePos(state, direction)
    if direction == "up" then state.pos = state.pos + Cords(0, 0, 1)
    elseif direction == "down" then state.pos = state.pos + Cords(0, 0, -1)
    else state.pos = Cords.getPosAhead(state.pos, state.turtleDirection) end
end

return Space