require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundCasingDropTerrainSounds = {};
	self.CompliSoundCasingDropTerrainSounds.Hit = {};
	self.CompliSoundCasingDropTerrainSounds.Hit.Concrete = CreateSoundContainer("CompliSound Casing Drop Small Hit Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundCasingDropTerrainSounds.Hit.Dirt = CreateSoundContainer("CompliSound Casing Drop Small Hit Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundCasingDropTerrainSounds.Hit.Sand = CreateSoundContainer("CompliSound Casing Drop Small Hit Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundCasingDropTerrainSounds.Hit.SolidMetal = CreateSoundContainer("CompliSound Casing Drop Small Hit SolidMetal", "0CompliSoundEmporium.rte");

	self.CompliSoundCasingDropTerrainSounds.Roll = {};
	self.CompliSoundCasingDropTerrainSounds.Roll.Concrete = CreateSoundContainer("CompliSound Casing Drop Small Roll Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundCasingDropTerrainSounds.Roll.Dirt = CreateSoundContainer("CompliSound Casing Drop Small Roll Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundCasingDropTerrainSounds.Roll.Sand = CreateSoundContainer("CompliSound Casing Drop Small Roll Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundCasingDropTerrainSounds.Roll.SolidMetal = CreateSoundContainer("CompliSound Casing Drop Small Roll SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundCasingDropMaxHits = 2;
	self.CompliSoundCasingDropMaxRolls = 2;
	
	self.CompliSoundCasingDropHits = 0;
	self.CompliSoundCasingDropRolls = 0;
	
	self.CompliSoundLastVel = self.Vel;
end

function ThreadedUpdate(self)
	self.CompliSoundImpulse = (self.Vel - self.CompliSoundLastVel) / TimerMan.DeltaTimeSecs * self.Vel.Magnitude * 0.1
	self.CompliSoundLastVel = Vector(self.Vel.X, self.Vel.Y)
end

function OnCollideWithTerrain(self, terrainID)
	if not CompliSoundTerrainIDs[terrainID] and terrainID ~= 0 then
		terrainID = 177; -- Default to concrete
	end
	
	if self.CompliSoundImpulse.Magnitude > 25 then
		if self.CompliSoundCasingDropHits < self.CompliSoundCasingDropMaxHits and terrainID ~= 0 then -- 0 = air
			self.CompliSoundCasingDropHits = self.CompliSoundCasingDropHits + 1;
			if self.CompliSoundCasingDropTerrainSounds.Hit[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundCasingDropTerrainSounds.Hit[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		end
	elseif self.CompliSoundImpulse.Magnitude > 6 then
		if self.CompliSoundCasingDropRolls < self.CompliSoundCasingDropMaxRolls and terrainID ~= 0 then -- 0 = air
			self.CompliSoundCasingDropRoll = self.CompliSoundCasingDropRolls + 1;
			if self.CompliSoundCasingDropTerrainSounds.Roll[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundCasingDropTerrainSounds.Roll[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		end
	end
end