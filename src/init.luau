type Component = any
type Pair = { left: Pair | Component | nil, right: Pair | Component | nil }

type Archetype = {
	componentIds: { number },
	componentTargets: { number },
	idToField: { [number]: number },
	entities: { number },
	fields: { { any } },
}

type EntityLocation = {
	archetype: Archetype,
	fieldIndex: number,
}

local World = {}
World.__index = World

function World.new()
	return setmetatable({
		nextEntityId = 100,
		entityLocations = {} :: { EntityLocation },
		archetypes = {} :: { Archetype },
		componentArchetypes = {},
	}, World)
end

export type World = typeof(World.new())

local function hash(componentIds: { number })
	return table.concat(componentIds, "_")
end

local function ensureArchetype(world: World, componentIds, componentTargets)
	-- Needs to take into account component ID + target, where
	-- relationship target is nillable or wildcard
	for _, archetype in world.archetypes do
		if hash(archetype.componentIds) == hash(componentIds) then
			if hash(archetype.componentTargets) == hash(componentTargets) then
				return archetype
			end
		end
	end

	local newArchetype: Archetype = {
		componentIds = componentIds,
		componentTargets = componentTargets,
		idToField = {},
		entities = {},
		fields = {},
	}

	for index, componentId in componentIds do
		newArchetype.fields[index] = {}
		newArchetype.idToField[componentId] = index

		if world.componentArchetypes[componentId] == nil then
			world.componentArchetypes[componentId] = {}
		end

		table.insert(world.componentArchetypes[componentId], newArchetype)
	end

	table.insert(world.archetypes, newArchetype)
	return newArchetype
end

local function transitionArchetype(world, entity, oldArchetype: Archetype, newArchetype: Archetype)
	local location = world.entityLocations[entity]
	local oldFieldIndex = location.fieldIndex

	local newFieldIndex = #newArchetype.entities + 1
	newArchetype.entities[newFieldIndex] = entity

	local oldNumEntities = #oldArchetype.entities
	local wasLastEntity = oldNumEntities == location.fieldIndex

	for index, oldField in oldArchetype.fields do
		local newField = newArchetype.fields[newArchetype.idToField[oldArchetype.componentIds[index]]]
		if newField then
			newField[newFieldIndex] = oldField[location.fieldIndex]
		end

		if not wasLastEntity then
			oldField[location.fieldIndex] = oldField[oldNumEntities]
		end

		oldField[oldNumEntities] = nil
	end

	if not wasLastEntity then
		oldArchetype.entities[oldFieldIndex] = oldArchetype.entities[oldNumEntities]
		world.entityLocations[oldArchetype.entities[oldFieldIndex]].fieldIndex = oldFieldIndex
	end

	oldArchetype.entities[oldNumEntities] = nil

	location.fieldIndex = newFieldIndex
	location.archetype = newArchetype
	return location.fieldIndex
end

function World:spawn()
	local entity = self.nextEntityId
	self.nextEntityId += 1

	local rootArchetype = ensureArchetype(self, {}, {})
	local fieldIndex = #rootArchetype.entities + 1
	rootArchetype.entities[fieldIndex] = entity

	self.entityLocations[entity] = { archetype = rootArchetype, fieldIndex = fieldIndex }
	return entity
end

function World:set(entity, data)
	local componentId = #data
	-- print("setting", componentId)

	local location = self.entityLocations[entity]
	local oldArchetype = location.archetype

	-- TODO: update existing

	local componentIds = table.clone(oldArchetype.componentIds)
	local componentTargets = table.clone(oldArchetype.componentTargets)

	local componentIndex = 1
	for index, id in componentIds do
		componentIndex = index

		if id > componentId then
			break
		end
	end

	local isRelation = data[1] == 2
	table.insert(componentIds, componentIndex, componentId)
	table.insert(componentTargets, componentIndex, if isRelation then data[2] else -1)

	-- print("	new component ids:", componentIds)
	-- print("	new component targets:", componentTargets)

	local newArchetype = ensureArchetype(self, componentIds, componentTargets)
	-- print("	new archetype:", newArchetype)

	local fieldIndex = transitionArchetype(self, entity, oldArchetype, newArchetype)
	newArchetype.fields[newArchetype.idToField[componentId]][fieldIndex] = if isRelation then data[3] else data[2]
end

function World:query(...)
	local terms = { ... }
	local possibleArchetypes
	local compatibleArchetypes = {}
	for _, component in terms do
		local componentId = #component
		-- print("checking", componentId)
		local associatedArchetypes = self.componentArchetypes[componentId]
		if associatedArchetypes == nil then
			error("no archetypes")
		end

		if possibleArchetypes == nil or #possibleArchetypes > #associatedArchetypes then
			possibleArchetypes = associatedArchetypes
		end
	end

	for _, archetype: Archetype in possibleArchetypes do
		local incompatible = false
		for _, component in terms do
			if archetype.idToField[#component] == nil then
				incompatible = true
			end

			if component[1] == 2 and component[2] ~= archetype.componentTargets[archetype.idToField[#component]] then
				incompatible = true
			end
		end

		if incompatible then
			continue
		end

		table.insert(compatibleArchetypes, archetype)
	end

	print("compatible", compatibleArchetypes)
end

return World
