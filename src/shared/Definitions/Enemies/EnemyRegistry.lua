local Enemies = {}
Enemies.__index = Enemies

function Enemies.new(
	Name,
	MaxEnergy,
	Energy,
	MaxHealth,
	Health,
	Damage,
	Xp,
	Speed,
	Attacks,
	Effects,
	AttacksInCooldown,
	Drops
)
	local NewEnemy = {}
	setmetatable(NewEnemy, Enemies)
	NewEnemy.Name = Name
	NewEnemy.MaxEnergy = 6
	NewEnemy.Energy = 0
	NewEnemy.MaxHealth = MaxHealth
	NewEnemy.Health = MaxHealth
	NewEnemy.Damage = Damage
	NewEnemy.Xp = Xp
	NewEnemy.Speed = Speed
	NewEnemy.Attacks = Attacks or {}
	NewEnemy.Effects = Effects or {}
	NewEnemy.AttacksInCooldown = AttacksInCooldown or {}
	NewEnemy.Drops = Drops or {}

	return NewEnemy
end
local EnemyList = {
	Enemy1 = Enemies.new(
		"Enemy1",
		6,
		0,
		20,
		20,
		3,
		10,
		4,
		{ "Slash", "Fireball", "Miasm", "Enrage" },
		{},
		{},
		{}
	),
}

function Enemies:TakeDamage(data) end
return EnemyList
