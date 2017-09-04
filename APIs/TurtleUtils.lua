--reqired modules: Cords, Movement

TurtleUtils = {}
TurtleUtils.__index = TurtleUtils 

local fuelMin
function TurtleUtils.initFuel()
    turtle.select(16)
    fuelMin = 1 + 4 * state.config.baseRadius
    if turtle.getFuelLevel() < state.config.baseRadius + fuelMin then 
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
    state.mode = Movement.modeEnum.search
    state.collectedResources = 0
    state.allSlotsEquipment = false
    state.modeReason = nil

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
    if data and TurtleUtils.isAllowedMaterial(data.name) then start = 16 end
    for i=start,1,-1 do
        turtle.select(i)
        turtle.dropDown()
        while turtle.getItemCount(i) ~= 0 do
            print("Droping items - full inventory")
            os.sleep(1)
            turtle.dropDown()
        end
    end
end

function TurtleUtils.isAllowedMaterial(name)
    for k, v in ipairs(state.config.materials) do
        if v.block == name or v.item == name then return true end
    end
    return false
end

function TurtleUtils.isEnoughFuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end
    local distance = Cords.distance(state.pos, Cords.new())
    turtle.select(16)
    -- 4 because in the worst case turtle must go around base
    while fuel <= distance + fuelMin do
        if turtle.refuel(0) then 
            turtle.refuel(1)
            fuel = turtle.getFuelLevel()
            if turtle.getItemCount(16) == 0 then state.allSlotsEquipment = false end
        else return false end
    end
    return true
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
                if data and TurtleUtils.isAllowedMaterial(data.name) then condition = true end
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
        if data and not TurtleUtils.isAllowedMaterial(data.name) then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(16)
    local data = turtle.getItemDetail(16)
    if data and not TurtleUtils.isAllowedMaterial(data.name)
       and not turtle.refuel(0) then turtle.drop() end
    if state.collectedResources > 15 then replaceResources() end 
end

local function findIncompleteSlot(material)
    for i=1,16 do
        local data = turtle.getItemDetail(i)
        if data and data.name == material then
            local free = turtle.getItemSpace(i)
            if free > 0 then
                return true, free
            end
        end
    end
    return false
end

local function moveMaterials()
    for i=1,15 do
        turtle.select(i)
        for j=i+1,16 do
            turtle.transferTo(j)
            if turtle.getItemDetail() == nil then
                return true, 64
            end
        end
    end
    return false
end

local function getItemMaterial(material)
    for k, v in ipairs(state.config.materials) do
        if v.block == material then return v.item end
    end
    assert(false, "Material not found")
end

local curMat = nil
local freeInSlot = 0
function TurtleUtils.prepareInvenory(material)
    material = getItemMaterial(material)
    if not state.allSlotsEquipment then TurtleUtils.cleanInventory() end
    
    if material ~= curMat or freeInSlot == 0 then
        local suc, free = findIncompleteSlot(material)
        if not suc then 
            suc, free = moveMaterials()
        end
        if suc then
            curMat = material
            freeInSlot = free
        else
            state.modeReason = "inventory"
            state.mode = Movement.modeEnum.goBack
            return false
        end
    else
        freeInSlot = freeInSlot - 1
    end
    return true
end

function TurtleUtils.initInventory()
    local function count(i)
        state.collectedResources = state.collectedResources + turtle.getItemCount(i)
    end
    TurtleUtils.cleanInventory() --clean to count only resources
    for i=1,15 do count(i) end
    local data = turtle.getItemDetail(16)
    if data and TurtleUtils.isAllowedMaterial(data.name) then count(16) end
    if state.collectedResources > 15 then replaceResources() end 
end

function TurtleUtils.isInSecureRange(cords, additionalRadious)
    local x, y, z = cords:unpack()
    local radius = state.config.baseRadius + (additionalRadious or 0)
    return math.abs(x) < radius and math.abs(y) < radius and math.abs(z) < radius 
end

return TurtleUtils
