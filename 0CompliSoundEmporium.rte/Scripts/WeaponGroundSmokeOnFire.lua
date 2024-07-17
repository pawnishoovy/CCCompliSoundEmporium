-- Usage notes:

-- To edit how much smoke is spawned you must set self.CompliSoundGroundSmokeStr in a previously-loaded Lua file's Create.
-- The default value assumes you want a pretty beefy effect.

function Create(self)
	if not self.CompliSoundGroundSmokeStr then
		self.CompliSoundGroundSmokeStr = 50;
	end
end

function OnFire(self)
	local smallAmount = math.min(30, self.CompliSoundGroundSmokeStr);
	for i = 1, smallAmount do
		
		local effect = CreateMOSRotating("CompliSound Ground Smoke Particle Small", "0CompliSoundEmporium.rte")
		effect.Pos = self.MuzzlePos + Vector(RangeRand(-1,1), RangeRand(-1,1)) * 3
		effect.Vel = self.Vel + Vector(math.random(90,150),0):RadRotate(math.pi * 2 / smallAmount * i + RangeRand(-2,2) / smallAmount)
		effect.Lifetime = effect.Lifetime * RangeRand(0.5,2.0)
		effect.AirResistance = effect.AirResistance * RangeRand(0.5,0.8)
		MovableMan:AddParticle(effect)
	end
	
	local largeAmount = math.max(0, self.CompliSoundGroundSmokeStr - 30);
	for i = 1, largeAmount do
		
		local effect = CreateMOSRotating("CompliSound Ground Smoke Particle Large", "0CompliSoundEmporium.rte")
		effect.Pos = self.MuzzlePos + Vector(RangeRand(-1,1), RangeRand(-1,1)) * 3
		effect.Vel = self.Vel + Vector(math.random(90,150),0):RadRotate(math.pi * 2 / largeAmount * i + RangeRand(-2,2) / largeAmount)
		effect.Lifetime = effect.Lifetime * RangeRand(0.5,2.0)
		effect.AirResistance = effect.AirResistance * RangeRand(0.5,0.8)
		MovableMan:AddParticle(effect)
	end
end