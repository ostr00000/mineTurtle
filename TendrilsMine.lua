--TODO inventory array, multiple materials, split project into modules
--TODO add knowns materials
--TODO move turtle position from space into state
--TODO replace hard return on inv and fuel
--TODO replace goToBasePoint() on goToTarget()

--global variable

--to config
material = "minecraft:quartz_ore"
inventoryMaterial = "minecraft:quartz"
baseRadius = 3
hasChargerInBase = true
mapName = "turtleWorld"
posName = "turtleState"
dbgName = "turtleDebug"
maxNumOfReturns = 1

--control
modeEnum = {
    stop = 0,
    search = 1,
    mine = 2,
    goBak = 3
}

--save all prints into file and print them
function initDbg()
    oldPrint = print
    dbg = fs.open(dbgName, "w")
    print = function(...) 
        for i, a in ipairs(arg) do
            if a == nil then dbg.write("nil\t")
            else dbg.write(tostring(a) .. "\t") end
        end
        dbg.write("\n")
        dbg.flush()
        for i, a in ipairs(arg) do oldprint(tostring(a) .. "\t") end
    end
end

initDbg()

state={}
local function reset()    
    state.numMaterials=0
    state.mode = modeEnum.search
    state.freeSpaceInSlot = 0
    state.collectedResources = 0
    state.allSlotsEquipment = false
    state.hardReturn = false

    state.turtleDirection = 0
--[[if turtle go forward: 
    direction 0 -> x++
    direction 1 -> y++
    direction 2 -> x--
    direction 3 -> y--
--]]
end

reset()



--Cords -> 3 numbers represent relative location to begining position
Cords = {}
function Cords.new(a, b, c)
	a = a or 0
	b = b or 0
	c = c or 0
    return {x=a, y=b, z=c}
end

function Cords.equals(cordA, cordB)
    if cordA == nil or cordB == nil then return false end
    return cordA.x == cordB.x and cordA.y == cordB.y and cordA.z == cordB.z
end

function Cords.add(cords, xx, yy, zz)
    if yy == nil and zz == nil then zz = xx.z; yy = xx.y; xx = xx.x end
    return Cords.new(cords.x + xx, cords.y + yy, cords.z + zz)
end

function Cords.sub(beginCords, endCords)
    return Cords.new(endCords.x-beginCords.x, endCords.y-beginCords.y, endCords.z-beginCords.z)
end

function Cords.distance(beginCords, endCords)
    local diff = Cords.sub(beginCords, endCords)
    return math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)
end

function Cords.length(cords)
    local sqrtsSum = cords.x * cords.x + cords.y * cords.y + cords.z * cords.z
    return math.sqrt(sqrtsSum)
end

function Cords.div(cords, scalar)
    return Cords.new(cords.x / scalar, cords.y / scalar, cords.z / scalar)
end

function Cords.mul(cords, scalar)
    return Cords.new(cords.x * scalar, cords.y * scalar, cords.z * scalar)
end

function Cords.round(cords)
    return Cords.new(math.floor(cords.x), math.floor(cords.y), math.floor(cords.z))
end

function Cords.tostring(cords)
    return "[x:"..cords.x.." y:"..cords.y.." z:"..cords.z.."]"
end

function Cords.isZero(cords)
    if cords.x == 0 and cords.y == 0 and cords.z == 0 then return true
    else return false end
end

function Cords.getPosAhead(cords)
    local d = state.turtleDirection
    if d == 0 then
        return Cords.add(cords, 1, 0, 0)
    elseif d == 1 then
        return Cords.add(cords, 0, 1, 0)
    elseif d == 2 then
        return Cords.add(cords, -1, 0, 0)
    else
        return Cords.add(cords, 0, -1, 0)
    end
end



--queue has been used to BFS algoritm
Queue = {}
function Queue.new()
    return {first=0, last=-1}
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



-- Space represent searched block position and turrtle current position
Space = {}
function Space.new ()
    local dim = {}
    dim[0] = {}
    dim[0][0] = {}
    dim[0][0][0] = "turtleHome"
    return {dim = dim, pos=Cords.new()} 
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
function Space.update(space, cords, val)
    local x, y, z = cords.x, cords.y, cords.z
    local dim = space.dim

    if dim[x] == nil then dim[x] = {} end
    if dim[x][y] == nil then dim[x][y] = {} end

    if val == material then 
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

function Space.initBase(space)
	local length = baseRadius - 1
	for i = -length, length do
		for j = -length, length do
			for k = -length, length do
				Space.update(space, Cords.new(i, j, k), "secured")
			end
		end
	end
	for i = 0, length do Space.update(space, Cords.new(i, 0, 0), "checked") end
end

function Space.findNearestMaterial(space, searchMaterial)
    local QueueData = {}
    function QueueData.new(fdir, axis, dir, cords) 
        return {firstDirection=fdir, 
                axis=axis, 
                direction=dir, 
                position=cords} 
    end
    function QueueData.tostring(queuedata)
        return "[firstDir:"..(queuedata.firstDirection or 0)
               .." axis:"..queuedata.axis 
               .." direction:"..queuedata.direction
               .." position:"..Cords.tostring(queuedata.position).."]"
    end

    local cord = space.pos 
    local q = Queue.new()

    Queue.push(q, QueueData.new("x+", "x",  1, Cords.add(cord,  1, 0, 0)))
    Queue.push(q, QueueData.new("x-", "x", -1, Cords.add(cord, -1, 0, 0)))
    Queue.push(q, QueueData.new("y+", "y",  1, Cords.add(cord, 0,  1, 0)))
    Queue.push(q, QueueData.new("y-", "y", -1, Cords.add(cord, 0, -1, 0)))
    Queue.push(q, QueueData.new("z+", "z",  1, Cords.add(cord, 0, 0,  1)))
    Queue.push(q, QueueData.new("z-", "z", -1, Cords.add(cord, 0, 0, -1)))

    while true do
        local data = Queue.pop(q)
        local axis, dir = data.axis, data.direction
        local position, fdir = data.position, data.firstDirection
        local mat = Space.getMaterial(space, position)

        if mat == searchMaterial then
            if searchMaterial == "nearest" then return data.firstDirection end
            return position
		elseif mat ~= "secured" then

			if axis == "x" then
				Queue.push(q, QueueData.new(fdir, "x", dir, Cords.add(position, dir, 0, 0)))
				Queue.push(q, QueueData.new(fdir, "y", 1,   Cords.add(position, 0, 1, 0)))
				Queue.push(q, QueueData.new(fdir, "y", -1,  Cords.add(position, 0, -1, 0)))
			elseif axis == "y" then
				Queue.push(q, QueueData.new(fdir, "y", dir, Cords.add(position, 0, dir, 0)))
			end

			if axis == "x" or axis == "y" then
				Queue.push(q, QueueData.new(fdir, "z", 1,   Cords.add(position, 0, 0, 1)))
				Queue.push(q, QueueData.new(fdir, "z", -1,  Cords.add(position, 0, 0, -1)))
			else
				Queue.push(q, QueueData.new(fdir, "z", dir, Cords.add(position, 0, 0, dir)))
			end
		end
    end
end

function Space.changePos(space, direction)
    if direction == "up" then space.pos = Cords.add(space.pos, 0, 0, 1)
    elseif direction == "down" then space.pos = Cords.add(space.pos, 0, 0, -1)
    else space.pos = Cords.getPosAhead(space.pos) end
end



checkPoint = {}
checkPoint.current = nil
checkPoint.round = 1
checkPoint.limit = 8
checkPoint.num = 0

space = Space.new()

--file functions
function loadFile(filename)
    local file = fs.open(filename, "r") --readonly
    local struct = textutils.unserialize(file.readAll())
    file.close()
    return struct
end

function saveFile(filename, struct)
    local file = fs.open(filename, "w") --rewrite file
    file.write(textutils.serialize(struct))
    file.close()
end

if fs.exists(mapName) then -- works only in root dir
	space.dim = loadFile(mapName) 
else
	Space.initBase(space)
end 
if fs.exists(posName) then
    local data = loadFile(posName)

    space.pos = data.pos
    checkPoint = data.checkPoint
    state=data.state
end



--turtle status functions
function isInSecureRange(cords, additionalRadious)
    local x, y, z = cords.x, cords.y, cords.z
    local radius = baseRadius + (additionalRadious or 0)
    return math.abs(x) < radius and math.abs(y) < radius and math.abs(z) < radius 
end

function isEnoughFuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end
    local distance = Cords.distance(space.pos, Cords.new())
    turtle.select(16)
    while fuel <= distance + 1 + 6 * (baseRadius - 1) do
        if turtle.refuel(0) then 
            turtle.refuel(1)
            fuel = turtle.getFuelLevel()
            if turtle.getItemCount(16) == 0 then state.allSlotsEquipment = false end
        else return false end
    end
    return true
end

function replaceResources()
    state.allSlotsEquipment = true
    local slots = {}
    local numOfTransfers = 0
    for i=1,16 do 
        slots[i] = turtle.getItemCount(i) 
        if slots[i] == 0 then numOfTransfers = numOfTransfers + 1 end
    end
    for i=1,16 do --check all slots
        if slots[i] > 1 then -- if slots is not empty
            local condition = (i ~= 16) -- and if slots is not fuel slot
            if not condition then -- or on fuel slot is resource
                local data = turtle.getItemDetail(16)
                if data and data.name == inventoryMaterial then condition = true end
            end
            if condition then
                turtle.select(i)
                for j=1,16 do --then for all slots
                    if i ~= j and slots[j] == 0 then -- other and empty slots
                        turtle.transferTo(j, 1) --transfer one resource
                        slots[j] = 1
                        slots[i] = slots[i] - 1
                        numOfTransfers = numOfTransfers - 1
                        if numOfTransfers == 0 then return end --if work is done return
                        --if on current pos resources left then find another slot
                        if slots[i] == 1 then break end 
                    end
                end
            end
        end
    end
end

function cleanInventory()
    for i=1,15 do
        local data = turtle.getItemDetail(i)
        if data and data.name ~= inventoryMaterial then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(16)
    local data = turtle.getItemDetail(16)
    if data and data.name ~= inventoryMaterial and not turtle.refuel(0) then turtle.drop() end
    if state.collectedResources > 15 then replaceResources() end 
end

function isEnoughSpace()
    if state.freeSpaceInSlot ~= 0 then return true end
    for i=1,15 do
        state.freeSpaceInSlot = turtle.getItemSpace(i)
        if state.freeSpaceInSlot > 0 then return true end
    end
    return false
end



--movement functions
dirFun = {} -- 1=detect, 2=cords modif, 3=arg for cords modif, 4=dig, 5=move, 6=inspect
dirFun["normal"] = {turtle.detect, Cords.getPosAhead, 0, turtle.dig, 
                    turtle.forward, turtle.inspect}
dirFun["up"]     = {turtle.detectUp, Cords.add, 1, turtle.digUp,
                    turtle.up, turtle.inspectUp}
dirFun["down"]   = {turtle.detectDown, Cords.add, -1, turtle.digDown, 
                    turtle.down, turtle.inspectDown}

function checkTerrain(dir, onSuccesValue)
    if dirFun[dir][1]() then
        local succes, data = dirFun[dir][6]()
        if succes and data.name == material then
            local cords = dirFun[dir][2](space.pos, 0, 0, dirFun[dir][3])
            if isInSecureRange(cords) then return false end
            Space.update(space, cords, onSuccesValue)
            return true
        end
    end
    return false
end

function turtleMove(dir)
    checkTerrain(dir, "void") -- check if block where I will move is wanted material
    if dirFun[dir][1]() then  --if there is block then dig
        dirFun[dir][4]() end

    repeat 
        local isSuccess = dirFun[dir][5]() --try move 
        if not isSuccess then 
            print("Trying to move")
            os.sleep(1) 
            if not isEnoughFuel() then
                print("ERROR: No fuel")
                return
            end
        end
    until isSuccess 
    Space.changePos(space, dir)

    if not state.allSlotsEquipment then cleanInventory() end
    local fuel, inventory = isEnoughFuel(), isEnoughSpace()
    if not fuel or not inventory then
        if not fuel then print("No fuel")
        else print("No space in inventory") end
        state.hardReturn = true
        state.mode = modeEnum.goBack
    end

    if Cords.equals(space.pos, checkPoint.current) then
        checkPoint.current = nil 
    end
    
    local toSave = {
        pos=space.pos,
        checkPoint=checkPoint,
        state=state
    }
    saveFile(posName, toSave)
end

function turtleTurn(right)
    if right then 
        turtle.turnRight()
        state.turtleDirection = (state.turtleDirection - 1) % 4
    else
        turtle.turnLeft()
        state.turtleDirection = (state.turtleDirection + 1) % 4
    end
end

function turtleSetDirection(direction)
    if (state.turtleDirection - 1) % 4 == direction then 
        turtleTurn(true)
    else
        while state.turtleDirection ~= direction do
            turtleTurn()
        end
    end
end

function lookAround()
    if Space.hasChecked(space, space.pos) then return false
    else Space.update(space, space.pos, "checked") end
    
    local finded = false
    for _=1,4 do
        finded = finded or checkTerrain("normal", material)
        turtleTurn()
    end
    finded = finded or checkTerrain("up", material)
    return finded or checkTerrain("down", material)
end

function goToTarget(targetCords)
    if isInSecureRange(space.pos, 1) then
        local nearestPoint = findNearestPoint(space.pos, targetCords)

        print("You are in secure zone:".. Cords.tostring(space.pos)) --INFO
        print("You want to go to:".. Cords.tostring(targetCords).. 
              " but you go to:".. Cords.tostring(nearestPoint)) --INFO

        local saved = Space.getMaterial(space, nearestPoint)
        Space.update(space, nearestPoint, "nearest")
        targetCords = Space.findNearestMaterial(space, "nearest")
        Space.update(space, nearestPoint, saved)

        targetCords = Cords.add(space.pos, decode(targetCords))
        print("Nearest point is:".. Cords.tostring(targetCords)) --INFO
    end

    local distance = Cords.sub(space.pos, targetCords)

    if distance.x ~= 0 then
        if distance.x < 0 then turtleSetDirection(2) else turtleSetDirection(0) end        
    elseif distance.y ~= 0 then
        if distance.y < 0 then turtleSetDirection(3) else turtleSetDirection(1) end
    end

    if distance.x ~= 0 or distance.y ~= 0 then
        turtleMove("normal")
    elseif distance.z ~= 0 then
        if distance.z > 0 then turtleMove("up") else turtleMove("down") end
    else
        print("ERROR: I need to go to filed where I am") 
    end
    
    if not state.hardReturn then lookAround() end
end

function findNearestPoint(from, to)
    print("findNearestPoint")
    local delta = Cords.sub(from, to)
    local length = Cords.length(delta)
    local dif = Cords.div(delta, length)
    
    local i, dest = 1, from
    repeat
        dest = Cords.round(Cords.add(from, Cords.mul(dif, i)))
        i = i + 1
    until Space.getMaterial(space, dest) ~= "secured" and not Cords.equals(dest, space.pos)
    return dest
end



--help quick check functions
function isOnInputPoint(x, y, z) return x == baseRadius and y == 0 and z == 0 end

function isOnLayer(layer, x, c)
    return math.abs(layer) == baseRadius 
        and (math.abs(x) < baseRadius or x == -baseRadius)
        and math.abs(c) <= baseRadius
end

function isOnBack(x, y, z) return x == -baseRadius end

function isAboveInput(x, y, z) return z > 0 end

function isUnderInput(x, y, z) return z < 0 end

function isOnForward(x, y, z) return x == baseRadius end

function isBetween(a, x, b) return a <= x and x <= b end



--checkPoints functions
function genCordX(c, n)
    if isBetween(0, c, n) or isBetween(7*n, c, 8*n-1) then return n
    elseif isBetween(3*n, c, 5*n) then return -n
    elseif isBetween(n+1, c, 3*n-1) then return 2*n-c
    elseif isBetween(5*n+1, c, 7*n-1) then return c-6*n
    else print("ERROR: wrong range X c:".. c .. " n:" .. n) end
end

function genCordY(c, n)
    if isBetween(n, c, 3*n) then return n
    elseif isBetween(5*n, c, 7*n) then return -n
    elseif isBetween(3*n+1, c, 5*n+1) then return 4*n-c
    elseif isBetween(0, c, n-1) then return c
    elseif isBetween(7*n+1, c, 8*n-1) then return 7*n-c
    else print("ERROR: wrong range Y c:".. c.. " n:".. n) end
end

function genCheckPoint()
    local coreFunction = function()
        if checkPoint.num == checkPoint.limit then
            checkPoint.round = checkPoint.round + 1 
            checkPoint.limit = checkPoint.limit + 8
            checkPoint.num = 0
        end
        local x = genCordX(checkPoint.num, checkPoint.round)
        local y = genCordY(checkPoint.num, checkPoint.round)
        checkPoint.current = Cords.new(x * 3, y * 3)
        checkPoint.num = checkPoint.num + 1
    end

    repeat
        checkPoint.current = nil
        coreFunction()
    until not isInSecureRange(checkPoint.current) 
          and not Space.hasChecked(space, checkPoint.current)
end

function decode(code)
    local char = string.sub(code, 1, 1)
    local sign = nil
    if string.sub(code, 2, 2) == "+" then sign = 1 else sign = -1 end

    if char == "x" then return Cords.new(sign, 0, 0)
    elseif char == "y" then return Cords.new(0, sign, 0)
    else return Cords.new(0, 0, sign) end
end



--main functions

function goToBasePoint()
    local cords = space.pos
    local x, y, z = cords.x, cords.y, cords.z
    if isInSecureRange(cords) or isOnInputPoint(x,y,z) then goToTarget(Cords.new())
    elseif isOnLayer(y,x,z) or isOnLayer(z,x,y) then goToTarget(Cords.add(space.pos, 1, 0, 0))
    elseif isAboveInput(x, y, z) then goToTarget(Cords.add(space.pos, 0, 0, -1))
    elseif isUnderInput(x, y, z) then goToTarget(Cords.add(space.pos, 0, 0, 1))
    elseif isOnBack(x, y, z) then goToTarget(Cords.add(Cords.new(), -baseRadius, baseRadius, 0))
    elseif isOnForward(x, y, z) then goToTarget(Cords.add(Cords.new(), baseRadius, 0, 0))
    else goToTarget(Cords.add(Cords.new(), baseRadius, 0, 0))
    end
end

function goSearch()
    if lookAround() or state.numMaterials > 0 then 
        state.mode = modeEnum.mine
    else
        if not checkPoint.current then genCheckPoint() end        
        goToTarget(checkPoint.current) 
    end
end

function mine()
    if state.numMaterials > 0 then
        goToTarget(Space.findNearestMaterial(space, material))
    else
        state.mode = modeEnum.search
    end
end

function goBack()
    if state.numMaterials > 0 and not state.hardReturn then
        state.mode = modeEnum.mine
    elseif Cords.isZero(space.pos) then
        state.mode = modeEnum.stop
    else 
        goToBasePoint()
    end
end

function charging()
    local numOfCharges = -1
    local chargeLevel = turtle.getFuelLevel()
    local chargeStep
    local maxLevel = turtle.getFuelLimit()
    repeat
        local percent = math.ceil(100 * chargeLevel / maxLevel)
        print("Charging: chargeLevel:".. chargeLevel.. " (".. percent.. "%)")
        numOfCharges = numOfCharges + 1
        os.sleep(1)
        chargeStep = chargeLevel
        chargeLevel = turtle.getFuelLevel()
    until chargeLevel == chargeStep
    if numOfCharges == 0 and maxLevel ~= chargeLevel then return false else return true end
end

function leaveItems()
    local success, data = turtle.inspectDown()
    if not success or data.name ~= "minecraft:chest" then return end

    local start = 15
    local data = turtle.getItemDetail(16)
    if data and data.name == inventoryMaterial then start = 16 end
    for i=start,1,-1 do
        turtle.select(i)
        while not turtle.dropDown() and turtle.getItemCount(i) ~= 0 do
            print("Droping items - full inventory")
            os.sleep(1) 
        end
    end
end

terminateFlag = not hasChargerInBase
numOfReturns = 0
function mainLoop()
    reset()
	step = 0
    while state.mode ~= modeEnum.stop do
        print("Returns:".. numOfReturns
              .." Step:".. step
              .." Fuel: ".. turtle.getFuelLevel()
              .. " Cords:".. Cords.tostring(space.pos))
        step = step + 1

        if state.mode == modeEnum.search then
            print("Resource searching mode")
            goSearch()
        elseif state.mode == modeEnum.mine then
            print("Resource mining mode")        
            mine()
        elseif state.mode == modeEnum.goBack then
            print("Return to start position")
            goBack()
        end

        saveFile(mapName, space.dim)
    end
    numOfReturns = numOfReturns + 1
    if numOfReturns >= maxNumOfReturns then terminateFlag = true end
end

--at start fuel check
function initFuel()
    turtle.select(16)
    if turtle.getFuelLevel() < 10 then 
        print("No fuel - refueling from 16th slot")
        for i=5, 1, -1 do
            print(i)
            os.sleep(1)
        end
        if turtle.refuel(1) then print("Refuel success")
        else print("Still no fuel"); return end
    end
end

--at start inventory check
function initInventory()
    local function count(i) 
        state.collectedResources = state.collectedResources + turtle.getItemCount(i)
    end
    cleanInventory() --clean to count only resources
    for i=1,15 do count(i) end
    local data = turtle.getItemDetail(16)
    if data and data.name == inventoryMaterial then count(16) end
    if state.collectedResources > 15 then replaceResources() end 
end



--main program
initFuel()
initInventory()

repeat
    mainLoop()
    leaveItems()
    turtleSetDirection(0)  
    if not charging() then break end
until terminateFlag

dbg.close()
