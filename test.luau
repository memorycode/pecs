local World = require("./init.luau")

local id = 0
local function component()
	id += 1
	local myId = id

	return setmetatable({}, {
		__len = function()
			return myId
		end,
		__call = function(_, data)
			return setmetatable({ 1, data }, {
				__len = function()
					return myId
				end,
			})
		end,
	})
end

local function relation()
	id += 1
	local myId = id

	return setmetatable({}, {
		__len = function()
			return myId
		end,
		__call = function(_, target, data)
			return setmetatable({ 2, target, data }, {
				__len = function()
					return myId
				end,
			})
		end,
	})
end

local Person = component()
local Car = component()
local ChildOf = component()

local world = World.new()
local person = world:spawn()
local car = world:spawn()

--print(person, car, world)
--world:set(car, Car("toyota"))
world:set(car, ChildOf(person, car))
for entity in world:query(ChildOf(person)) do
	print("child:", entity)
end
--world:set(person, Person("michael"))

-- for id, car in world:query(Car) do
-- end

-- for id, car in world:query(ChildOf(person)) do
-- end
