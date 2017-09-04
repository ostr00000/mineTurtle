--Cords -> 3 numbers represent relative location to begin position

Cords = {}
Cords.__index = Cords

function Cords:unpack() return self.x, self.y, self.z end

function Cords.load(cord) return setmetatable(cord, Cords) end

function Cords.new(a, b, c)
    if a~= nil and b == nil and c == nil then
        a, b, c = a:unpack()
    else
        a, b, c = a or 0, b or 0, c or 0
    end
    return setmetatable({x=a, y=b, z=c}, Cords)
end

function Cords.__eq(cordA, cordB)
    if cordA == nil or cordB == nil then return false end
    return cordA.x == cordB.x and cordA.y == cordB.y and cordA.z == cordB.z
end

function Cords.__add(cordA, cordB)
    return Cords.new(cordA.x + cordB.x, cordA.y + cordB.y, cordA.z + cordB.z)
end

function Cords.__sub(cordA, cordB)
    return Cords.new(cordA.x - cordB.x, cordA.y - cordB.y, cordA.z - cordB.z)
end

function Cords:distance(cord)
    local diff = self - cord
    return math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)
end

function Cords:length()
    local square = self * self
    return math.sqrt(square.x + square.y + square.z)
end

function Cords.__div(cords, scalar)
    return Cords.new(cords.x / scalar, cords.y / scalar, cords.z / scalar)
end

function Cords.__mul(cords, scalar)
    if type(scalar) == "number" then  
        return Cords.new(cords.x * scalar, cords.y * scalar, cords.z * scalar) end
    local c = scalar
    return Cords.new(cords.x * c.x, cords.y * c.y, cords.z * c.z)    
end

function Cords:round()
    return Cords.new(math.floor(self.x), math.floor(self.y), math.floor(self.z))
end

function Cords:__tostring()
    return "[x:"..self.x.." y:"..self.y.." z:"..self.z.."]"
end

function Cords:isZero()
    if self.x == 0 and self.y == 0 and self.z == 0 then return true
    else return false end
end

function Cords:getPosAhead(direction)
    if     direction == 0 then return self + Cords(1, 0, 0)
    elseif direction == 1 then return self + Cords(0, 1, 0)
    elseif direction == 2 then return self + Cords(-1, 0, 0)
    else                       return self + Cords(0, -1, 0) 
    end
end

setmetatable(Cords, {__call = function(_, ...) return Cords.new(...) end})

return Cords
