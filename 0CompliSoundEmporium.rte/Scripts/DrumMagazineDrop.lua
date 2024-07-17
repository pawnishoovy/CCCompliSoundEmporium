require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundMagazineDropTerrainSounds = {};
	self.CompliSoundMagazineDropTerrainSounds.Concrete = CreateSoundContainer("CompliSound Magazine Drop Drum Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundMagazineDropTerrainSounds.Dirt = CreateSoundContainer("CompliSound Magazine Drop Drum Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundMagazineDropTerrainSounds.Sand = CreateSoundContainer("CompliSound Magazine Drop Drum Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundMagazineDropTerrainSounds.SolidMetal = CreateSoundContainer("CompliSound Magazine Drop Drum SolidMetal", "0CompliSoundEmporium.rte");
end

function OnCollideWithTerrain(self, terrainID)
	if not CompliSoundTerrainIDs[terrainID] and terrainID ~= 0 then
		terrainID = 177; -- Default to concrete
	end
	
	if not self.CompliSoundMagazineDropDone then
		self.CompliSoundMagazineDropDone = true;
		if terrainID ~= 0 then -- 0 = air
			if self.CompliSoundMagazineDropTerrainSounds[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundMagazineDropTerrainSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		end
	end
end