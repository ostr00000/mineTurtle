--required modules Cords, Space, TurtleUtils
--CheckPoints are points where turtle going to check if there are resources

CheckPoint = {}
CheckPoint.__index = CheckPoint

function CheckPoint.create()
    local cp = {current = nil, round = 1, limit = 8, num = 0}
    return setmetatable(cp, CheckPoint)
end

local function isBetween(a, x, b) return a <= x and x <= b end

local function genCordX(c, n)
    if isBetween(0, c, n) or isBetween(7*n, c, 8*n-1) then return n
    elseif isBetween(3*n, c, 5*n) then return -n
    elseif isBetween(n+1, c, 3*n-1) then return 2*n-c
    elseif isBetween(5*n+1, c, 7*n-1) then return c-6*n
    else print("ERROR: wrong range X c:".. c .. " n:" .. n) end
end

local function genCordY(c, n)
    if isBetween(n, c, 3*n) then return n
    elseif isBetween(5*n, c, 7*n) then return -n
    elseif isBetween(3*n+1, c, 5*n+1) then return 4*n-c
    elseif isBetween(0, c, n-1) then return c
    elseif isBetween(7*n+1, c, 8*n-1) then return 7*n-c
    else print("ERROR: wrong range Y c:".. c.. " n:".. n) end
end

function CheckPoint:genCheckPoint(space)
    local coreFunction = function()
        if self.num == self.limit then
            self.round = self.round + 1 
            self.limit = self.limit + 8
            self.num = 0
        end
        local x = genCordX(self.num, self.round)
        local y = genCordY(self.num, self.round)
        self.current = Cords(x * 3, y * 3)
        self.num = self.num + 1
    end

    repeat
        self.current = nil
        coreFunction()
    until not TurtleUtils.isInSecureRange(self.current) 
          and not space:hasChecked(self.current)
end

return CheckPoint
