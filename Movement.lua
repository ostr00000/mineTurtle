--required modules: Cords, Space, TurtleUtils, IOmodule

Movement = {}
Movement.__index = Movement

local dirFun = {} -- 1=detect, 2=cords modif, 3=arg for cords modif, 4=dig, 5=move, 6=inspect
dirFun["normal"] = {turtle.detect, Cords.getPosAhead, 0, turtle.dig, 
                    turtle.forward, turtle.inspect}
dirFun["up"]     = {turtle.detectUp, Cords.__add, 1, turtle.digUp,
                    turtle.up, turtle.inspectUp}
dirFun["down"]   = {turtle.detectDown, Cords.__add, -1, turtle.digDown, 
                    turtle.down, turtle.inspectDown}

Movement.modeEnum = {
    stop = 0,
    search = 1,
    mine = 2,
    goBack = 3
}

local function turtleTurn(right)
    if right then 
        turtle.turnRight()
        state.turtleDirection = (state.turtleDirection - 1) % 4
    else
        turtle.turnLeft()
        state.turtleDirection = (state.turtleDirection + 1) % 4
    end
end

local function turtleSetDirection(direction)
    if (state.turtleDirection - 1) % 4 == direction then 
        turtleTurn(true)
    else
        while state.turtleDirection ~= direction do
            turtleTurn()
        end
    end
end

function Movement.setDirection(dir) turtleSetDirection(dir) end

local function checkTerrain(dir, onSuccesValue)
    if dirFun[dir][1]() then
        local succes, data = dirFun[dir][6]()
        if succes and data.name == state.config.material then
            local cords
            if dir == "normal" then cords = state.pos:getPosAhead(state.turtleDirection)
            else cords = state.pos + Cords(0, 0, dirFun[dir][3]) end
            if TurtleUtils.isInSecureRange(cords, state.config) then return false end
            space:update(cords, onSuccesValue, state)
            return true
        end
    end
    return false
end

local function lookAround()
    if space:hasChecked(state.pos) then return false
    else space:update(state.pos, "checked", state) end
    
    local finded = false
    for _=1,4 do
        finded = checkTerrain("normal", state.config.material) or finded
        turtleTurn()
    end
    finded = checkTerrain("up", state.config.material) or finded
    return checkTerrain("down", state.config.material) or finded
end

local function changePos(direction)
    if direction == "up" then state.pos = state.pos + Cords(0, 0, 1)
    elseif direction == "down" then state.pos = state.pos + Cords(0, 0, -1)
    else state.pos = Cords.getPosAhead(state.pos, state.turtleDirection) end
end

local function turtleMove(dir)
    checkTerrain(dir, "void") -- check if block where I will move is wanted material
    if dirFun[dir][1]() then  --if there is block then dig
        dirFun[dir][4]() end

    repeat 
        local isSuccess = dirFun[dir][5]() --try move 
        if not isSuccess then 
            print("Trying to move")
            os.sleep(1) 
            if not TurtleUtils.isEnoughFuel() then
                print("ERROR: No fuel")
                return
            end
        end
    until isSuccess 
    changePos(dir)

    if not state.allSlotsEquipment then TurtleUtils.cleanInventory() end
    local fuel = TurtleUtils.isEnoughFuel()
    local inventory = TurtleUtils.isEnoughSpace()
    if not fuel or not inventory then
        if not fuel then print("No fuel")
        else print("No space in inventory") end
        state.hardReturn = true
        state.mode = Movement.modeEnum.goBack
    end

    if state.pos == state.checkPoint.current then
        state.checkPoint.current = nil 
    turtle.digDown()
    end
    
    IOmodule.saveStatus()
end

local function goToTarget(targetCords)
    if TurtleUtils.isInSecureRange(state.pos, state.config, 1) then
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

    if distance.x ~= 0 or distance.y ~= 0 then turtleMove("normal")
    elseif distance.z ~= 0 then
        if distance.z > 0 then turtleMove("up")
        else turtleMove("down")end
    else
        print("ERROR: I need to go to field where I am") 
    end
    
    if not state.hardReturn then lookAround() end
end



local function goSearch()
    if lookAround() or state.numMaterials > 0 then 
        state.mode = Movement.modeEnum.mine
    else
        if not state.checkPoint.current then
            state.checkPoint:genCheckPoint(space, state.config) 
        end
        goToTarget(state.checkPoint.current)
    end
end

local function mine()
    if state.numMaterials > 0 then
        goToTarget(space:findNearestMaterial(state.pos, state.config.material))
    else
        state.mode = Movement.modeEnum.search
    end
end

local function goBack()
    if state.numMaterials > 0 and not state.hardReturn then
        state.mode = Movement.modeEnum.mine
    elseif state.pos:isZero() then
        state.mode = Movement.modeEnum.stop
    else
        goToTarget(Cords())
    end
end



function Movement.nextStep()
    if state.mode == Movement.modeEnum.search then
        print("Resource searching mode")
        goSearch()
    elseif state.mode == Movement.modeEnum.mine then
        print("Resource mining mode")        
        mine()
    elseif state.mode == Movement.modeEnum.goBack then
        print("Return to start position")
        goBack()
    end
end

return Movement
