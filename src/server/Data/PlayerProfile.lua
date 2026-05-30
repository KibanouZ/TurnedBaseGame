local PlayerProfile = {}
PlayerProfile.__index = PlayerProfile

local Defaults = {
	Stats = {
		MaxHealth = 25,
		Health = 25,
		Speed = 5,
		Strength = 5,
		Intelligence = 5,
		CritChanceBase = 0.05,
		CritDamageMultiplier = 1.5,
		Luck = 5,
		MaxEnergy = 6,
		Energy = 0,
	},
	Gold = 0,
	Attacks = { "Slash", "Fireball", "PowerStrike" },
	Effects = {},
	AttackCooldowns = {},
}

function PlayerProfile.new(overrides)
	local profile = setmetatable({}, PlayerProfile)
	overrides = overrides or {}

	for k, v in pairs(Defaults) do
		profile[k] = overrides[k] or v
	end

	return profile
end

return PlayerProfile
