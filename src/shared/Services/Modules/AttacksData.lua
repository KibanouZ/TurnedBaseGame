local Attacks = {
	Slash = {

		Damage = 5,
		Type = "Physical",
		EnergyCost = 0,
		Cooldown = 0,
		Description = "A basic slash attack with a sword. No energy cost.",
	},
	Fireball = {
		Damage = 25,
		Type = "Magic",
		EnergyCost = 1,
		Cooldown = 2,
		Description = "A fiery projectile that burns the enemy. Costs 1 energy.",
	},
	ManaShot = {
		Damage = 5,
		Type = "Magic",
		EnergyCost = 0,
		Cooldown = 0,
		Description = "A quick burst of magical energy. No energy cost.",
	},
	PowerStrike = {
		Damage = 15,
		Type = "Physical",
		EnergyCost = 2,
		Cooldown = 3,
		Description = "A powerful strike that deals heavy damage. Costs 2 energy.",
	},
	Heal = {
		Damage = -10,
		Type = "Magic",
		EnergyCost = 1,
		Cooldown = 2,
		Description = "A healing spell that restores health. Costs 1 energy.",
	},
}

return Attacks
