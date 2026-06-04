local TurnQueue = {}
TurnQueue.__index = TurnQueue

function TurnQueue.new()
	local self = setmetatable({}, TurnQueue)
	self.queue = {}
	return self
end
-- ================================================
--          BUILDING TURN QUEUE
-- ================================================
function TurnQueue.Build(allies, enemies)
	local self = TurnQueue.new()

	for _, ally in ipairs(allies) do
		table.insert(self.queue, ally)
	end

	for _, enemy in ipairs(enemies) do
		table.insert(self.queue, {
			entity = enemy,
			speed = enemy.speed or 5,
			kind = "enemy",
		})
	end

	table.sort(self.queue, function(a, b)
		if a.speed == b.speed then
			return tostring(a.entity.UserId or a.entity.Name) < tostring(b.entity.UserId or b.entity.Name)
		end
		return a.speed > b.speed
	end)

	self.currentIndex = 1
	return self
end
-- ================================================
--          CHECK BATTLE END
-- ================================================
function TurnQueue:HasLivingAllies()
	for _, entry in ipairs(self.queue) do
		if entry.kind == "player" and entry.health > 0 then
			return true
		end
	end
	return false
end

function TurnQueue:HasLivingEnemies()
	for _, entry in ipairs(self.queue) do
		if entry.kind == "enemy" and entry.entity.currentHealth > 0 then
			return true
		end
	end
	return false
end
function TurnQueue:GetCurrent()
	if #self.queue == 0 then
		return nil
	end

	return self.queue[self.currentIndex]
end
-- ================================================
--  NEXT TURN / REMOVE DEAD
-- ================================================
function TurnQueue:Next()
	self.currentIndex += 1
	if self.currentIndex > #self.queue then
		self.currentIndex = 1
	end
	return self:GetCurrent()
end

function TurnQueue:RemoveDead()
	for i = #self.queue, 1, -1 do
		local entry = self.queue[i]
		local health = entry.kind == "player" and entry.entity.health or entry.entity.currentHealth
		if health <= 0 then
			table.remove(self.queue, i)
			-- ajusta o índice se removeu antes da posição atual
			if i <= self.currentIndex then
				self.currentIndex = math.max(1, self.currentIndex - 1)
			end
		end
	end
end

return TurnQueue
