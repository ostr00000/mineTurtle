--global variable
material = "minecraft:quartz_ore"
inventoryMaterial = "minecraft:quartz"
numMaterials=0
mode = 1
freeInventory = 0
collectedResources = 0
allSlotsEquipment = false
hardReturn = false
turtleDirection = 0
--[[if turtle go forward: 
    direction 0 -> x++
    direction 1 -> y++
    direction 2 -> x--
    direction 3 -> y--
--]]



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
    dim[0][0][0] = "turtle"
    return {dim = dim, pos=Cords.new()} 

end

function Space.update(space, cords, val)
    local x, y, z = cords.x, cords.y, cords.z    
    dim = space.dim

    if dim[x] == nil then dim[x] = {} end
    if dim[x][y] == nil then dim[x][y] = {} end

    if val == material then 
        if dim[x][y][z] ~= val then numMaterials = numMaterials + 1 end
    elseif val == "void" then 
        numMaterials = numMaterials - 1
        collectedResources = collectedResources + 1
    else print("ERROR: unknown material") end
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

function Space.changePos(space, direction)
    if direction == "up" then space.pos = Cords.add(space.pos, 0, 0, 1)
    elseif direction == "down" then space.pos = Cords.add(space.pos, 0, 0, -1)
    else space.pos = Cords.getPosAhead(space.pos) end
end



--help functions
dirFun = {} -- 1=detect, 2=cords modif, 3=arg for cords modif, 4=dig, 5=move, 6=inspect
dirFun["normal"] = {turtle.detect, Cords.getPosAhead, 0, turtle.dig, 
                    turtle.forward, turtle.inspect}
dirFun["up"]     = {turtle.detectUp, Cords.add, 1, turtle.digUp,
                    turtle.up, turtle.inspectUp}
dirFun["down"]   = {turtle.detectDown, Cords.add, -1, turtle.digDown, 
                    turtle.down, turtle.inspectDown}

space = Space.new()

function checkTerrain(dir, onSuccesValue)
    if dirFun[dir][1]() then
        local succes, data = dirFun[dir][6]()
        if succes and data.name == material then
            local cords = dirFun[dir][2](space.pos, 0, 0, dirFun[dir][3])
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
    while fuel <= distance + 1 do
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
    until isSuccess 
    Space.changePos(space, dir) --tell map that turtle changed position
    
    if not allSlotsEquipment then cleanInventory() end
    if not isEnoughFuel() or not isEnoughSpace() then hardReturn = true; mode = 3 end
end

function turtleTurn()
    turtle.turnLeft()
    turtleDirection = (turtleDirection + 1) % 4
end

function turtleSetDirection(direction)
    while turtleDirection ~= direction do
        turtleTurn()
    end
end

function lookAround()
    local finded = false
    for _=1,4 do
        if checkTerrain("normal", material) then finded = true end
        turtleTurn()
    end
    if checkTerrain("up", material) then finded = true end
    if checkTerrain("down", material) then finded = true end
    return finded
end



--main functions
function goForward()
    if lookAround() then
        mode = 2
    else 
        turtleMove("normal")
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
        goToTarget(Cords.new())
    end
end



--main program
turtle.select(16)
if turtle.getFuelLevel() == 0 then 
    print("No fuel - refueling from 16th slot")
    for i=5, 1, -1 do
        print(i)
        os.sleep(1)
    end
    if turtle.refuel(1) then print("Refuel success")
    else print("Still no fuel"); return end
end

print("Set item to mine (leave empty to set default:", material, "):")
answer = io.read()
if answer ~= "" then material = answer end
print("Set item after minig (leave empty to set default:", inventoryMaterial, "):")
answer = io.read()
if answer ~= "" then inventoryMaterial = answer end

cleanInventory()
for i=1,16 do 
    collectedResources = collectedResources + turtle.getItemCount(i)
end
cleanInventory()

step = 1
while mode ~= 0 do
    print("Step:", step, " Fuel: ", turtle.getFuelLevel())
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
    --os.sleep(1)
end

turtleSetDirection(0)
