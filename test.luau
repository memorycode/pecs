local World = require("./src/init.luau")

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
local ChildOf = relation()

local world = World.new()

local michael = world:spawn()
local andy = world:spawn()

local toyota = world:spawn()
local honda = world:spawn()

world:set(michael, Person("michael"))
world:set(andy, Person("andy"))

world:set(toyota, ChildOf(michael))
world:set(honda, ChildOf(andy))
world:set(toyota, Car())
world:set(honda, Car())

print("archetypes:", world.archetypes)
for entity in world:query(Car, ChildOf(andy)) do
	print("child:", entity, entity == honda)
end
