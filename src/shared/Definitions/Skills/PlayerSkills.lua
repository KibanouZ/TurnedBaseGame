local Attacks = {}
Attacks.__index = Attacks

function Attacks.new(Data)
	local NewAttack = {}
	setmetatable(NewAttack, Attacks)
	NewAttack.Damage = Data.Damage or 0
	NewAttack.Type = Data.Type or "Physical"
	NewAttack.ActionType = Data.ActionType or "Attack"
	NewAttack.EnergyCost = Data.EnergyCost or 0
	NewAttack.Cooldown = Data.Cooldown or 0
	NewAttack.Effect = Data.Effect or {}
	NewAttack.TargetType = Data.TargetType or "single"
	NewAttack.DotType = Data.DotType or nil
	return NewAttack
end
local AttackList = {
	Slash = Attacks.new({
		Damage = 5,
		Type = "Physical",
		ActionType = "Attack",
		Cooldown = 0,
		EnergyCost = 0,
		TargetType = "single",
	}),
	Fireball = Attacks.new({
		Damage = 10,
		Type = "Magic",
		ActionType = "Attack",
		EnergyCost = 1,
		Cooldown = 2,
		TargetType = "single",
	}),
	Miasm = Attacks.new({
		Damage = 3,
		Type = "Dot",
		ActionType = "Debuff",
		EnergyCost = 1,
		Cooldown = 2,
		DotType = "Poison",
		TargetType = "single",
		Effect = { DamagePerTurn = 2, Duration = 3 },
	}),
	Enrage = Attacks.new({
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
	PowerStrike = Attacks.new({
		Damage = 15,
		Type = "Physical",
		ActionType = "Attack",
		Cooldown = 2,
		EnergyCost = 2,
		TargetType = "single",
	}),
}
return AttackList
