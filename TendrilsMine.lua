
--global variable
state = nil
space = nil
configName = "config.txt"

--load APIs
local APIs = {
  "Cords", "Heap", "Space",
  "TurtleUtils", "IOmodule",
  "CheckPoint", "Movement"
}
_G["path"] = string.gsub(shell.getRunningProgram(), "TendrilsMine.lua", "")
for _, name in ipairs(APIs) do
    print("Loading "..name..": ", os.loadAPI(path.."APIs/"..name..".lua"))
    _G[name] = _G[name..".lua"][name]
end

--main program
--load or create state and map
IOmodule.init(configName)
if not TurtleUtils.initFuel() then return end
TurtleUtils.initInventory()

local terminateFlag = not state.config.hasChargerInBase
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

repeat
    mainLoop()
    TurtleUtils.leaveItems()
    Movement.setDirection(0)
    TurtleUtils.stateReset() 
    if not TurtleUtils.charging() then break end
until terminateFlag

IOmodule.close()
os.reload()
