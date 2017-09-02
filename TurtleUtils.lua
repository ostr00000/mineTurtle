--reqired modules: Cords

TurtleUtils = {}
TurtleUtils.__index = TurtleUtils 

function TurtleUtils.initFuel()
    turtle.select(16)
    if turtle.getFuelLevel() < 10 then 
        print("No fuel - refueling from 16th slot")
        for i=5, 1, -1 do
            print(i)
            os.sleep(1)
        end
        if turtle.refuel(1) then print("Refuel success")
        else 
            print("Still no fuel")
            return false
        end
    end
    return true
end

function TurtleUtils.stateReset()
    state.numMaterials=0
    state.mode = Movement.modeEnum.search
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

function TurtleUtils.charging()
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

function TurtleUtils.leaveItems()
    local success, data = turtle.inspectDown()
    if not success or data.name ~= "minecraft:chest" then return end

    local start = 15
    local data = turtle.getItemDetail(16)
    if data and data.name == state.config.inventoryMaterial then start = 16 end
    for i=start,1,-1 do
        turtle.select(i)
        while not turtle.dropDown() and turtle.getItemCount(i) ~= 0 do
            print("Droping items - full inventory")
            os.sleep(1) 
        end
    end
end

function TurtleUtils.isEnoughFuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end
    local distance = Cords.distance(state.pos, Cords.new())
    turtle.select(16)
    while fuel <= distance + 1 + 5 * (state.config.baseRadius - 1) do
        if turtle.refuel(0) then 
            turtle.refuel(1)
            fuel = turtle.getFuelLevel()
            if turtle.getItemCount(16) == 0 then state.allSlotsEquipment = false end
        else return false end
    end
    return true
end

function TurtleUtils.isEnoughSpace()
    if state.freeSpaceInSlot ~= 0 then return true end
    for i=1,15 do
        state.freeSpaceInSlot = turtle.getItemSpace(i)
        if state.freeSpaceInSlot > 0 then return true end
    end
    return false
end


local function replaceResources()
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
                if data and data.name == state.config.inventoryMaterial then condition = true end
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

function TurtleUtils.cleanInventory()
    for i=1,15 do
        local data = turtle.getItemDetail(i)
        if data and data.name ~= state.config.inventoryMaterial then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(16)
    local data = turtle.getItemDetail(16)
    if data and data.name ~= state.config.inventoryMaterial 
       and not turtle.refuel(0) then turtle.drop() end
    if state.collectedResources > 15 then replaceResources() end 
end

function TurtleUtils.initInventory()
    local function count(i)
        state.collectedResources = state.collectedResources + turtle.getItemCount(i)
    end
    TurtleUtils.cleanInventory() --clean to count only resources
    for i=1,15 do count(i) end
    local data = turtle.getItemDetail(16)
    if data and data.name == state.config.inventoryMaterial then count(16) end
    if state.collectedResources > 15 then replaceResources() end 
end

function TurtleUtils.isInSecureRange(cords, config, additionalRadious)
    local x, y, z = cords:unpack()
    local radius = config.baseRadius + (additionalRadious or 0)
    return math.abs(x) < radius and math.abs(y) < radius and math.abs(z) < radius 
end

return TurtleUtils
