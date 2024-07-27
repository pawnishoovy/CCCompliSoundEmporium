require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundGrenadePhysicsTerrainSounds = {};
	self.CompliSoundGrenadePhysicsTerrainSounds.HitHard = {};
	self.CompliSoundGrenadePhysicsTerrainSounds.HitHard.Concrete = CreateSoundContainer("CompliSound Grenade Type One Hit Concrete Hard", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitHard.Dirt = CreateSoundContainer("CompliSound Grenade Type One Hit Dirt Hard", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitHard.Sand = CreateSoundContainer("CompliSound Grenade Type One Hit Sand Hard", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitHard.SolidMetal = CreateSoundContainer("CompliSound Grenade Type One Hit SolidMetal Hard", "0CompliSoundEmporium.rte");
	
	self.CompliSoundGrenadePhysicsTerrainSounds.HitMed = {};
	self.CompliSoundGrenadePhysicsTerrainSounds.HitMed.Concrete = CreateSoundContainer("CompliSound Grenade Type One Hit Concrete Med", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitMed.Dirt = CreateSoundContainer("CompliSound Grenade Type One Hit Dirt Med", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitMed.Sand = CreateSoundContainer("CompliSound Grenade Type One Hit Sand Med", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitMed.SolidMetal = CreateSoundContainer("CompliSound Grenade Type One Hit SolidMetal Med", "0CompliSoundEmporium.rte");
	
	self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft = {};
	self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft.Concrete = CreateSoundContainer("CompliSound Grenade Type One Hit Concrete Soft", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft.Dirt = CreateSoundContainer("CompliSound Grenade Type One Hit Dirt Soft", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft.Sand = CreateSoundContainer("CompliSound Grenade Type One Hit Sand Soft", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft.SolidMetal = CreateSoundContainer("CompliSound Grenade Type One Hit SolidMetal Soft", "0CompliSoundEmporium.rte");

	self.CompliSoundGrenadePhysicsTerrainSounds.Roll = {};
	self.CompliSoundGrenadePhysicsTerrainSounds.Roll.Concrete = CreateSoundContainer("CompliSound Grenade Type One Roll Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.Roll.Dirt = CreateSoundContainer("CompliSound Grenade Type One Roll Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.Roll.Sand = CreateSoundContainer("CompliSound Grenade Type One Roll Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundGrenadePhysicsTerrainSounds.Roll.SolidMetal = CreateSoundContainer("CompliSound Grenade Type One Roll SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundLastVel = self.Vel;
	
	self.CompliSoundHitTimer = Timer();
	self.CompliSoundHitDelay = 0;
	
	self.CompliSoundGraceRollPlayed = false;
end

function Update(self)
	self.CompliSoundImpulse = (self.Vel - self.CompliSoundLastVel) / TimerMan.DeltaTimeSecs * self.Vel.Magnitude * 0.1
	self.CompliSoundLastVel = Vector(self.Vel.X, self.Vel.Y)
end

function OnCollideWithTerrain(self, terrainID)
	if not CompliSoundTerrainIDs[terrainID] and terrainID ~= 0 then
		terrainID = 177; -- Default to concrete
	end
	
	if self.CompliSoundGraceRollPlayed == false and self.Vel.Magnitude < 3 and self.CompliSoundHitTimer:IsPastSimMS(self.CompliSoundHitDelay) then
		self.CompliSoundGraceRollPlayed = true;
		if terrainID ~= 0 then -- 0 = air
			if self.CompliSoundGrenadePhysicsTerrainSounds.Roll[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundGrenadePhysicsTerrainSounds.Roll[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		end
	end
	
	if self.CompliSoundHitTimer:IsPastSimMS(self.CompliSoundHitDelay) then
		--if self.CompliSoundImpulse.Magnitude > 3 then
		--	print(self.CompliSoundImpulse.Magnitude)
		--end
		if self.CompliSoundImpulse.Magnitude > 35 then

			self.CompliSoundHitTimer:Reset();
			self.CompliSoundHitDelay = self.CompliSoundHitDelay + 25;
			if terrainID ~= 0 then -- 0 = air
				if self.CompliSoundGrenadePhysicsTerrainSounds.HitHard[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundGrenadePhysicsTerrainSounds.HitHard[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			end
		elseif self.CompliSoundImpulse.Magnitude > 25 then
			self.CompliSoundHitTimer:Reset();
			self.CompliSoundHitDelay = self.CompliSoundHitDelay + 25;
			if terrainID ~= 0 then -- 0 = air
				if self.CompliSoundGrenadePhysicsTerrainSounds.HitMed[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundGrenadePhysicsTerrainSounds.HitMed[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			end
		elseif self.CompliSoundImpulse.Magnitude > 7 then
			self.CompliSoundHitTimer:Reset();
			self.CompliSoundHitDelay = self.CompliSoundHitDelay + 50;
			if terrainID ~= 0 then -- 0 = air
				if self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundGrenadePhysicsTerrainSounds.HitSoft[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			end
		elseif self.CompliSoundImpulse.Magnitude > 3 then
			self.CompliSoundHitTimer:Reset();
			self.CompliSoundHitDelay = self.CompliSoundHitDelay + 150;
			if terrainID ~= 0 then -- 0 = air
				if self.CompliSoundGrenadePhysicsTerrainSounds.Roll[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundGrenadePhysicsTerrainSounds.Roll[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			end
		end
	end
end