type Component = any
type Pair = { left: Pair | Component | nil, right: Pair | Component | nil }

local World = {}
World.__index = World

function World.new()
	return setmetatable({
		nextEntityId = 100,
		entityLocations = {},
		archetypes = {},
	}, World)
end

local function hash(componentIds: { number })
	table.sort(componentIds)
	return table.concat(componentIds, "_")
end

local nilpair = {}

local function ensureArchetype(world, componentIds)
	-- Needs to take into account component ID + target, where
	-- relationship target is nillable or wildcard

	for _, archetype in world.archetypes do
		if hash(archetype.componentIds) == hash(componentIds) then
			return archetype
		end
	end

	local newArchetype = {
		componentIds = componentIds,
		idToField = {},
		entities = {},
		fields = {},
	}

	for index, componentId in componentIds do
		newArchetype.fields[index] = {}
		newArchetype.idToField[componentId] = index
	end

	table.insert(world.archetypes, newArchetype)
	return newArchetype
end

local function transitionArchetype(world, entity, componentIds: { number })
	local location = world.entityLocations[entity]

	local archetype = ensureArchetype(world, componentIds)
	local index = #archetype.entities + 1
	archetype.entities[index] = entity

	location.archetype = archetype
	location.archetypeIndex = index
	return archetype
end

function World:spawn()
	local entity = self.nextEntityId
	self.nextEntityId += 1
	self.entityLocations[entity] = {}

	transitionArchetype(self, entity, {})
	return entity
end

function World:set(entity, data)
	local location = self.entityLocations[entity]
	local componentIds = table.clone(location.archetype.componentIds)
	table.insert(componentIds, #data)

	transitionArchetype(self, entity, componentIds)

	local fieldIndex = location.archetype.idToField[#data]
	local field = location.archetype.fields[fieldIndex]
	field[location.archetypeIndex] = data

	print("fields:", location.archetype.fields)
end

function World:query(...)
	local terms = select("#", ...)
	local compatibleArchetypes = {}
end

return World
