--global variable

--to config
material = "minecraft:quartz_ore"
inventoryMaterial = "minecraft:quartz"
baseRadius = 3
hasChargerInBase = true
mapName = "turtleWorld"
posName = "turtleCords"

--control
turtleDirection = 0
--[[if turtle go forward: 
    direction 0 -> x++
    direction 1 -> y++
    direction 2 -> x--
    direction 3 -> y--
--]]



numMaterials
mode
freeInventory
collectedResources
allSlotsEquipment
hardReturn

function reset()
    numMaterials=0
    mode = 1
    freeInventory = 0
    collectedResources = 0
    allSlotsEquipment = false
    hardReturn = false
end


--Cords -> 3 numbers represent relative location to begining position
Cords = {}
function Cords.new ()
    return {x=0, y=0, z=0}
end

function Cords.add(cords, xx, yy, zz)
    return {x=cords.x + xx, y=cords.y + yy, z=cords.z + zz}
end

function Cords.sub(beginCords, endCords)
    return {x=endCords.x-beginCords.x, y=endCords.y-beginCords.y, z=endCords.z-beginCords.z}
end

function Cords.distance(beginCords, endCords)
    local diff = Cords.sub(beginCords, endCords)
    return math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)
end

function Cords.isZeroPosition(cords)
    if cords.x == 0 and cords.y == 0 and cords.z == 0 then return true
    else return false end
end

function Cords.getPosAhead(cords)
    local d = turtleDirection
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

function Space.hasChecked(space)
    local dim = space.dim
    local x, y, z = space.pos.x, space.pos.y, space.pos.z
    if dim[x] ~= nil and dim[x][y] ~= nil and dim[x][y][z] == "checked"
    then return true else return false end
end

function Space.update(space, cords, val)
    local x, y, z = cords.x, cords.y, cords.z
    local dim = space.dim

    if dim[x] == nil then dim[x] = {} end
    if dim[x][y] == nil then dim[x][y] = {} end

    if val == material then 
        if dim[x][y][z] ~= val then numMaterials = numMaterials + 1 end --first time apperar
    elseif val == "void" then --material will be mined
        numMaterials = numMaterials - 1
        collectedResources = collectedResources + 1
    elseif val ~= "checked" then print("ERROR: unknown material") end
    dim[x][y][z] = val
end

function Space.isMaterial(space, cords)
    if space.dim[cords.x] ~= nil and space.dim[cords.x][cords.y] ~= nil
       and space.dim[cords.x][cords.y][cords.z] == material then
        return true
    else 
        return false
    end
end

function Space.findNearestMaterial(space)
    local cord = space.pos 
    local q = Queue.new()

    Queue.push(q, {a="x", d=1, p=Cords.add(cord, 1, 0, 0)})
    Queue.push(q, {a="x", d=-1, p=Cords.add(cord, -1, 0, 0)})
    Queue.push(q, {a="y", d=1, p=Cords.add(cord, 0, 1, 0)})
    Queue.push(q, {a="y", d=-1, p=Cords.add(cord, 0, -1, 0)})
    Queue.push(q, {a="z", d=1, p=Cords.add(cord, 0, 0, 1)})
    Queue.push(q, {a="z", d=-1, p=Cords.add(cord, 0, 0, -1)})

    while true do
        local data = Queue.pop(q)
        local axis, direction, position = data.a, data.d, data.p
        if Space.isMaterial(space, position) then
            return position
        end

        if axis == "x" then
            Queue.push(q, {a="x", d=direction, p=Cords.add(position, direction, 0, 0)})
            Queue.push(q, {a="y", d=1, p=Cords.add(position, 0, 1, 0)})
            Queue.push(q, {a="y", d=-1, p=Cords.add(position, 0, -1, 0)})
        elseif axis == "y" then
            Queue.push(q, {a="y", d=direction, p=Cords.add(position, 0, direction, 0)})
        end
        if axis == "x" or axis == "y" then
            Queue.push(q, {a="z", d=1, p=Cords.add(position, 0, 0, 1)})
            Queue.push(q, {a="z", d=-1, p=Cords.add(position, 0, 0, -1)})
        else
            Queue.push(q, {a="z", d=direction, p=Cords.add(position, 0, 0, direction)})
        end
    end
end

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

if fs.exists(mapName) then space.dim = loadFile(mapName) end -- works only in root dir
if fs.exists(posName) then
    local data = loadFile(posName)
    turtleDirection = data.dir
    space.pos = data.pos
end

function Space.changePos(space, direction)
    if direction == "up" then space.pos = Cords.add(space.pos, 0, 0, 1)
    elseif direction == "down" then space.pos = Cords.add(space.pos, 0, 0, -1)
    else space.pos = Cords.getPosAhead(space.pos) end

    saveFile(posName, {dir = turtleDirection, pos = space.pos})
end



    




--help functions
dirFun = {} -- 1=detect, 2=cords modif, 3=arg for cords modif, 4=dig, 5=move, 6=inspect
dirFun["normal"] = {turtle.detect, Cords.getPosAhead, 0, turtle.dig, 
                    turtle.forward, turtle.inspect}
dirFun["up"]     = {turtle.detectUp, Cords.add, 1, turtle.digUp,
                    turtle.up, turtle.inspectUp}
dirFun["down"]   = {turtle.detectDown, Cords.add, -1, turtle.digDown, 
                    turtle.down, turtle.inspectDown}



function isInSecureRange(x, y, z)
    return math.abs(x) < baseRadius and math.abs(y) < baseRadius and math.abs(z) < baseRadius 
end

function checkTerrain(dir, onSuccesValue)
    if dirFun[dir][1]() then
        local succes, data = dirFun[dir][6]()
        if succes and data.name == material then
            local cords = dirFun[dir][2](space.pos, 0, 0, dirFun[dir][3])
            if isInSecureRange(cords.x, cords.y, cords.z) then return false end
            Space.update(space, cords, onSuccesValue)
            return true
        end
    end
    return false
end

function isEnoughFuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end
    local distance = Cords.distance(space.pos, Cords.new())
    turtle.select(16)
    while fuel <= distance + 1 + 6 * baseRadius do
        if turtle.refuel(0) then 
            turtle.refuel(1)
            fuel = turtle.getFuelLevel()
            if turtle.getItemCount(16) == 0 then allSlotsEquipment = false end
        else return false end
    end
    return true
end

function replaceResources()
    allSlotsEquipment = true
    local slots = {}
    local numOfTransfers = 0
    for i=1,16 do 
        slots[i] = turtle.getItemCount(i) 
        if slots[i] == 0 then numOfTransfers = numOfTransfers + 1 end
    end
    for i=1,16 do
        if slots[i] > 1 then
            turtle.select(i)
            for j=1,16 do
                if i ~= j and slots[j] == 0 then                    
                    turtle.transferTo(j, 1)
                    slots[j] = 1
                    slots[i] = slots[i] - 1
                    numOfTransfers = numOfTransfers - 1
                    if slots[i] == 1 then break end
                end
            end
            if numOfTransfers == 0 then return end
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
    if data and data.name ~= inventoryMaterial 
       and not turtle.refuel(0) then turtle.drop() end
        

    if collectedResources > 15 then replaceResources() end
end

function isEnoughSpace()
    if freeInventory ~= 0 then return true end
    for i=1,15 do
        freeInventory = turtle.getItemSpace(i)
        if freeInventory > 0 then return true end
    end
    return false
end

function turtleMove(dir)
    checkTerrain(dir, "void") -- check if block where I will move is wanted material
    if dirFun[dir][1]() then  --if there is block then dig
        dirFun[dir][4]() end
    repeat 
        local isSuccess = dirFun[dir][5]() --move
        if not isSuccess then print("trying to move"); os.sleep(1) end
    until isSuccess 
    Space.changePos(space, dir) --tell map that turtle changed position
    
    if not allSlotsEquipment then cleanInventory() end
    if not isEnoughFuel() or not isEnoughSpace() then hardReturn = true; mode = 3 end
end

function turtleTurn(right)
    if right then 
        turtle.turnRight()
        turtleDirection = (turtleDirection - 1) % 4
    else
        turtle.turnLeft()
        turtleDirection = (turtleDirection + 1) % 4
    end
end

function turtleSetDirection(direction)
    if (turtleDirection - 1) % 4 == direction then 
        turtleTurn(true)
    else
        while turtleDirection ~= direction do
            turtleTurn()
        end
    end
end

function lookAround()
    if Space.hasChecked(space) then return false
    else Space.update(space, space.pos, "checked") end
    
    local finded = false
    for _=1,4 do
        if checkTerrain("normal", material) then finded = true end
        turtleTurn()
    end
    if checkTerrain("up", material) then finded = true end
    if checkTerrain("down", material) then finded = true end
    return finded
end

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

--main functions
function goForward()
    if lookAround() then
        mode = 2
    else 
        turtleMove("normal")
    end
end

function goToBasePoint()
    local x, y, z = space.pos.x, space.pos.y, space.pos.z
    if isInSecureRange(x,y,z) or isOnInputPoint(x,y,z) then goToTarget(Cords.new())
    elseif isOnLayer(y,x,z) or isOnLayer(z,x,y) then goToTarget(Cords.add(space.pos, 1, 0, 0))
    elseif isAboveInput(x, y, z) then goToTarget(Cords.add(space.pos, 0, 0, -1))
    elseif isUnderInput(x, y, z) then goToTarget(Cords.add(space.pos, 0, 0, 1))
    elseif isOnBack(x, y, z) then goToTarget(Cords.add(Cords.new(), -baseRadius, baseRadius, 0))
    elseif isOnForward(x, y, z) then goToTarget(Cords.add(Cords.new(), baseRadius, 0, 0))
    else goToTarget(Cords.add(Cords.new(), baseRadius, 0, 0))
    end
end

function goToTarget(targetCords)
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
    
    if not hardReturn then lookAround() end
end

function mine()
    if numMaterials > 0 then
        goToTarget(Space.findNearestMaterial(space))
    else
        mode = 3
    end
end

function goBack()
    if numMaterials > 0 and not hardReturn then
        mode = 2
    elseif Cords.isZeroPosition(space.pos) then
        mode = 0
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
        print("charging: chargeLevel:", chargeLevel, " (", percent, "%)")
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
            print("droping items - full inventory")
            os.sleep(1) 
        end
    end
end

numOfReturns = 0
function mainLoop()
    reset()
    while mode ~= 0 do
        print("Returns:", numOfReturns, " Step:", step, " Fuel: ", turtle.getFuelLevel())
        step = step + 1
        if mode == 1 then
            print("Resource searching mode")
            goForward()
        elseif mode == 2 then
            print("Resource mining mode")        
            mine()
        elseif mode == 3 then
            print("Return to start position")
            goBack()
        end
    end
    numOfReturns = numOfReturns + 1
end



--main program
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

--print("Set item to mine (leave empty to set default:", material, "):")
--answer = io.read()
--if answer ~= "" then material = answer end
--print("Set item after minig (leave empty to set default:", inventoryMaterial, "):")
--answer = io.read()
--if answer ~= "" then inventoryMaterial = answer end

cleanInventory()
for i=1,16 do 
    collectedResources = collectedResources + turtle.getItemCount(i)
end
cleanInventory()

repeat
    mainLoop()
    leaveItems()
    saveFile(mapName, space.dim)
    turtleSetDirection(0)  
    if not charging() then break end
until not hasChargerInBase
