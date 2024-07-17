require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundCannonShellHitSound = CreateSoundContainer("CompliSound Casing Drop Cannon Shell Hit Generic", "0CompliSoundEmporium.rte");
end

function OnCollideWithTerrain(self, terrainID)
	if not self.CompliSoundCasingDropDone then
		self.CompliSoundCasingDropDone = true;
		self.CompliSoundCannonShellHitSound:Play(self.Pos);
	end
end