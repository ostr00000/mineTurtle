
--global variable
state = nil
space = nil
configName = "config.txt"

local function loadAPI(name)
	fs.delete(name)
	fs.copy(name..".lua", name)
	print("Loading "..name, os.loadAPI(name))
	_G[name] = _G[name][name]
end

loadAPI("Cords")
loadAPI("Heap")
loadAPI("Space") --Cords, Heap, TurtleUtils
loadAPI("TurtleUtils") --Cords, Movement
loadAPI("IOmodule")--Cords, Space, TurtleUtils
loadAPI("CheckPoint") --Cords, Space, TurtleUtils
loadAPI("Movement") --Cords, Space, TurtleUtils, IOmodule

IOmodule.init(configName)

terminateFlag = not state.config.hasChargerInBase
local numOfReturns = 0
local function mainLoop()
	  local step = 0
    while state.mode ~= Movement.modeEnum.stop do
        print("Returns:"..numOfReturns.." Step:"..step
              .." Fuel:"..turtle.getFuelLevel().." Cords:"..tostring(state.pos))
        step = step + 1
        Movement.nextStep(state)
        IOmodule.saveMap()
    end
    numOfReturns = numOfReturns + 1
    if numOfReturns >= state.config.maxNumOfReturns then terminateFlag = true end
end


--main program
if not TurtleUtils.initFuel() then return end
TurtleUtils.initInventory()

repeat
    mainLoop()
    TurtleUtils.leaveItems()
    Movement.setDirection(0)
    TurtleUtils.stateReset() 
    if not TurtleUtils.charging() then break end
until terminateFlag

IOmodule.close()
os.reload()
