local EAttacks = {}
EAttacks.__index = EAttacks

function EAttacks.new(Data)
	local NewEAttack = {}
	setmetatable(NewEAttack, EAttacks)
	NewEAttack.Damage = Data.Damage or 0
	NewEAttack.Type = Data.Type or "Physical"
	NewEAttack.ActionType = Data.ActionType or "Attack"
	NewEAttack.EnergyCost = Data.EnergyCost or 0
	NewEAttack.Cooldown = Data.Cooldown or 0
	NewEAttack.Effect = Data.Effect or {}
	NewEAttack.TargetType = Data.TargetType or "single"
	NewEAttack.DotType = Data.DotType or nil
	return NewEAttack
end
local AttackList = {
	Slash = EAttacks.new({
		Damage = 5,
		Type = "Physical",
		ActionType = "Attack",
		Cooldown = 0,
		EnergyCost = 0,
		TargetType = "single",
	}),
	Fireball = EAttacks.new({
		Damage = 10,
		Type = "Magic",
		ActionType = "Attack",
		EnergyCost = 1,
		Cooldown = 2,
		TargetType = "single",
	}),
	Miasm = EAttacks.new({
		Damage = 3,
		Type = "Dot",
		ActionType = "Debuff",
		EnergyCost = 1,
		Cooldown = 2,
		DotType = "Poison",
		TargetType = "single",
		Effect = { DamagePerTurn = 2, Duration = 3 },
	}),
	Enrage = EAttacks.new({
		Type = "Physical",
		ActionType = "Buff",
		Effect = {
			DamageIncrease = 3,
			Duration = 3,
		},
		Cooldown = 3,
		EnergyCost = 1,
		TargetType = "self",
	}),
}
return AttackList
