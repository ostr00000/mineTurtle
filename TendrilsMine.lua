--TODO inventory array, multiple materials
--TODO add knowns materials
--TODO replace hard return on inv and fuel

--global variable

--to config
Config = {}
Config.material = "minecraft:quartz_ore"
Config.inventoryMaterial = "minecraft:quartz"
Config.baseRadius = 10
Config.hasChargerInBase = false
Config.mapName = "turtleWorld"
Config.staName = "turtleState"
Config.dbgName = "turtleDebug"
Config.maxNumOfReturns = 1



--save all prints into file and print them
function initDbg()
    oldPrint = print
    dbg = fs.open(Config.dbgName, "w")
    print = function(...) 
        for i, v in ipairs(arg) do
            if v == nil then dbg.write("nil\t")
            else dbg.write(tostring(v) .. "\t") end
        end
        dbg.write("\n")
        dbg.flush()
        for i, v in ipairs(arg) do oldPrint(v) end
    end
end
initDbg()


--DEBUG TEST
local function loadAPI(name)
	fs.delete(name)
	fs.copy(name..".lua", name)
	print("Loading "..name, os.loadAPI(name))
	_G[name] = _G[name][name]
end

loadAPI("Cords")
loadAPI("Heap")
loadAPI("Space")
loadAPI("CheckPoint")

--control
modeEnum = {
    stop = 0,
    search = 1,
    mine = 2,
    goBack = 3
}

state = {config=Config}
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


checkPoint = CheckPoint.create()
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

if fs.exists(Config.staName) then
    local data = loadFile(Config.staName)
    checkPoint = setmetatable(data.checkPoint, CheckPoint)
    
    if checkPoint.current then
        checkPoint.current = Cords.load(checkPoint.current)
    end
    state = data.state
    state.pos = Cords.load(state.pos)
else
    state.pos = Cords.new()
end
if fs.exists(Config.mapName) then -- works only in root dir
    space.dim = loadFile(Config.mapName) 
else
    space:initBase(Config.baseRadius, state)
end 


--turtle status functions

function isEnoughFuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end
    local distance = Cords.distance(state.pos, Cords.new())
    turtle.select(16)
    while fuel <= distance + 1 + 5 * (Config.baseRadius - 1) do
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
                if data and data.name == Config.inventoryMaterial then condition = true end
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
        if data and data.name ~= Config.inventoryMaterial then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(16)
    local data = turtle.getItemDetail(16)
    if data and data.name ~= Config.inventoryMaterial and not turtle.refuel(0) then turtle.drop() end
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
dirFun["up"]     = {turtle.detectUp, Cords.__add, 1, turtle.digUp,
                    turtle.up, turtle.inspectUp}
dirFun["down"]   = {turtle.detectDown, Cords.__add, -1, turtle.digDown, 
                    turtle.down, turtle.inspectDown}


function checkTerrain(dir, onSuccesValue)
    if dirFun[dir][1]() then
        local succes, data = dirFun[dir][6]()
        if succes and data.name == Config.material then
            local cords
            if dir == "normal" then cords = state.pos:getPosAhead(state.turtleDirection)
            else cords = state.pos + Cords(0, 0, dirFun[dir][3]) end
            if Space.isInSecureRange(cords, Config) then return false end
            space:update(cords, onSuccesValue, state)
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
    Space.changePos(state, dir)

    if not state.allSlotsEquipment then cleanInventory() end
    local fuel, inventory = isEnoughFuel(), isEnoughSpace()
    if not fuel or not inventory then
        if not fuel then print("No fuel")
        else print("No space in inventory") end
        state.hardReturn = true
        state.mode = modeEnum.goBack
    end

    if state.pos == checkPoint.current then
        checkPoint.current = nil 
		turtle.digDown()
    end
    
    local toSave = {
        checkPoint=checkPoint,
        state=state
    }
    saveFile(Config.staName, toSave)
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
    if space:hasChecked(state.pos) then return false
    else space:update(state.pos, "checked", state) end
    
    local finded = false
    for _=1,4 do
        finded = checkTerrain("normal", Config.material) or finded
        turtleTurn()
    end
    finded = checkTerrain("up", Config.material) or finded
    return checkTerrain("down", Config.material) or finded
end

function goToTarget(targetCords)
    if Space.isInSecureRange(state.pos, Config, 1) then
    		local testType = function(obj, typ) return getmetatable(obj) == typ end
    		assert(testType(state.pos, Cords), "ASSERT: goToTarget: not Cords: state.pos")
    		assert(testType(targetCords, Cords), "ASSERT: goToTarget: not Cords: targetCords")
    		
    		print("You are in secure zone:", state.pos,
              "You want to go to:", targetCords)--INFO
    		
	      targetCords = space:findNearestPosition(state.pos, targetCords)
        print("But you go to:", targetCords) --INFO
    end

    local distance = targetCords - state.pos

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
        print("ERROR: I need to go to field where I am") 
    end
    
    if not state.hardReturn then lookAround() end
end


--main functions

function goSearch()
    if lookAround() or state.numMaterials > 0 then 
        state.mode = modeEnum.mine
    else
        if not checkPoint.current then checkPoint:genCheckPoint(space, Config) end
        goToTarget(checkPoint.current)
    end
end

function mine()
    if state.numMaterials > 0 then
        goToTarget(space:findNearestMaterial(state.pos, Config.material))
    else
        state.mode = modeEnum.search
    end
end

function goBack()
    if state.numMaterials > 0 and not state.hardReturn then
        state.mode = modeEnum.mine
    elseif state.pos:isZero() then
        state.mode = modeEnum.stop
    elseif state.pos == Cords(Config.baseRadius, 0, 0) or space.isInSecureRange(state.pos, Config) then
        goToTarget(Cords())
    else
        goToTarget(Cords(Config.baseRadius, 0, 0))
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
    if data and data.name == Config.inventoryMaterial then start = 16 end
    for i=start,1,-1 do
        turtle.select(i)
        while not turtle.dropDown() and turtle.getItemCount(i) ~= 0 do
            print("Droping items - full inventory")
            os.sleep(1) 
        end
    end
end

terminateFlag = not Config.hasChargerInBase
numOfReturns = 0
function mainLoop()
    reset()
	step = 0
    while state.mode ~= modeEnum.stop do
        print("Returns:"..numOfReturns.." Step:"..step
              .." Fuel:"..turtle.getFuelLevel().." Cords:"..Cords.__tostring(state.pos))
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

        saveFile(Config.mapName, space.dim)
    end
    numOfReturns = numOfReturns + 1
    if numOfReturns >= Config.maxNumOfReturns then terminateFlag = true end
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
        else 
			print("Still no fuel")
			return false
		end
    end
	return true
end

--at start inventory check
function initInventory()
    local function count(i)
        state.collectedResources = state.collectedResources + turtle.getItemCount(i)
    end
    cleanInventory() --clean to count only resources
    for i=1,15 do count(i) end
    local data = turtle.getItemDetail(16)
    if data and data.name == Config.inventoryMaterial then count(16) end
    if state.collectedResources > 15 then replaceResources() end 
end



--main program
if not initFuel() then return end
initInventory()

repeat
    mainLoop()
    leaveItems()
    turtleSetDirection(0)  
    if not charging() then break end
until terminateFlag

local toSave = {
    checkPoint=checkPoint,
    state=state
}
saveFile(Config.staName, toSave)

dbg.close()
