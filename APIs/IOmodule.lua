--required files: configName.txt
--required modules: Cords, Space, TurtleUtils
--saves and load files

IOmodule = {}
IOmodule.__index = IOmodule

local function loadFile(filename)
    local file = fs.open(path..filename, "r") --readonly
    local struct = textutils.unserialize(file.readAll())
    file.close()
    return struct
end

local function saveFile(filename, struct)
    local file = fs.open(path..filename, "w") --rewrite file
    file.write(textutils.serialize(struct))
    file.close()
end 

function IOmodule.saveMap()
    saveFile(state.config.mapName, space.dim)
end

function IOmodule.saveStatus()
    saveFile(state.config.stateName, state)
end

--save all prints into file and print them
local dbg
local function initDbg(debugerName)
    local oldPrint = print
    dbg = fs.open(path..debugerName, "w")
    _G["print"] = function(...) 
        for i, v in ipairs(arg) do
            if v == nil then dbg.write("nil\t")
            else dbg.write(tostring(v) .. "\t") end
        end
        dbg.write("\n")
        dbg.flush()
        for i, v in ipairs(arg) do oldPrint(v) end
    end
end

local function checkConfig(config1, config2)
    for k, v in ipairs(config1) do
        if config2[k] ~= v then return false end
    end
    for k, v in ipairs(config2) do
        if config1[k] ~= v then return false end
    end
    return true
end

function IOmodule.init(configName)
    local config = loadFile(configName)
    if config.debug then initDbg(config.debugerName) end
    
    --load or create state
    local state = {}
    if fs.exists(path..config.stateName) then
        print("Loading file with state")
        state = loadFile(config.stateName)
        assert(checkConfig(state.config, config), "different configurations")
        state.checkPoint = setmetatable(state.checkPoint, CheckPoint)
        if state.checkPoint.current then
            state.checkPoint.current = Cords.load(state.checkPoint.current)
        end

        state.pos = Cords.load(state.pos)
        _G["state"] = state
    else
        print("Generate state")
        state.config = config
        state.pos = Cords.new()
        state.checkPoint = CheckPoint.create()
        _G["state"] = state
        TurtleUtils.stateReset()
    end
    
    
    --load or create map
    local space = Space.new()
    if fs.exists(path..config.mapName) then
        print("Loading file with map")
        space.dim = loadFile(config.mapName) 
    else
        print("Generate map")
        space:initBase(config.baseRadius, state)
    end
    _G["space"] = space
    
end

function IOmodule.close()
    IOmodule.saveStatus()
    dbg.close()
end

return IOmodule
