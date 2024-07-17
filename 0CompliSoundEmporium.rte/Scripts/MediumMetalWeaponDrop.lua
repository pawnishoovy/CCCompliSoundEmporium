require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundWeaponDropTerrainSounds = {};
	self.CompliSoundWeaponDropTerrainSounds.Concrete = CreateSoundContainer("CompliSound Weapon Drop Medium Metal Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundWeaponDropTerrainSounds.Dirt = CreateSoundContainer("CompliSound Weapon Drop Medium Metal Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundWeaponDropTerrainSounds.Sand = CreateSoundContainer("CompliSound Weapon Drop Medium Metal Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundWeaponDropTerrainSounds.SolidMetal = CreateSoundContainer("CompliSound Weapon Drop Medium Metal SolidMetal", "0CompliSoundEmporium.rte");
end

function OnDetach(self)
	self.CompliSoundWeaponDropDone = false;
end

function OnCollideWithTerrain(self, terrainID)
	if not CompliSoundTerrainIDs[terrainID] and terrainID ~= 0 then
		terrainID = 177; -- Default to concrete
	end
	
	if not self.CompliSoundWeaponDropDone then
		self.CompliSoundWeaponDropDone = true;
		if terrainID ~= 0 then -- 0 = air
			if self.CompliSoundWeaponDropTerrainSounds[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundWeaponDropTerrainSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		end
	end
end