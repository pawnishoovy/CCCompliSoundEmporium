-- Usage notes:

-- If your gun fires multiple particles, you MUST make sure only one of them has this script.
-- This means you must either fire via Lua, or via emitter. Normal Rounds firing MOPixels cannot do this.

require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundBulletTerrainSounds = {};
	self.CompliSoundBulletTerrainSounds.Concrete = CreateSoundContainer("CompliSound Light Bullet Impact Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainSounds.Dirt = CreateSoundContainer("CompliSound Light Bullet Impact Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainSounds.Sand = CreateSoundContainer("CompliSound Light Bullet Impact Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainSounds.SolidMetal = CreateSoundContainer("CompliSound Light Bullet Impact SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundBulletTerrainGFX = {};
	self.CompliSoundBulletTerrainGFX.Concrete = CreateMOSRotating("CompliSound GFX Light Bullet Impact Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainGFX.Dirt = CreateMOSRotating("CompliSound GFX Light Bullet Impact Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainGFX.Sand = CreateMOSRotating("CompliSound GFX Light Bullet Impact Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainGFX.SolidMetal = CreateMOSRotating("CompliSound GFX Light Bullet Impact SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundBulletTerrainExtraGFX = {};
	self.CompliSoundBulletTerrainExtraGFX.Concrete = CreateMOSRotating("CompliSound GFX Light Bullet Impact Concrete Extra", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainExtraGFX.Dirt = CreateMOSRotating("CompliSound GFX Light Bullet Impact Dirt Extra", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainExtraGFX.Sand = CreateMOSRotating("CompliSound GFX Light Bullet Impact Sand Extra", "0CompliSoundEmporium.rte");
	self.CompliSoundBulletTerrainExtraGFX.SolidMetal = CreateMOSRotating("CompliSound GFX Light Bullet Impact SolidMetal Extra", "0CompliSoundEmporium.rte");
end

function OnCollideWithTerrain(self, terrainID)
	if self.CompliSoundBulletImpactDone ~= true then
		self.CompliSoundBulletImpactDone = true;
		if terrainID ~= 0 then -- 0 = air
			if self.CompliSoundBulletTerrainSounds[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundBulletTerrainSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
			if self.CompliSoundBulletTerrainGFX[CompliSoundTerrainIDs[terrainID]] ~= nil then
				local GFX = self.CompliSoundBulletTerrainGFX[CompliSoundTerrainIDs[terrainID]]:Clone()
				GFX.Pos = self.Pos
				GFX.Vel = Vector(self.Vel.X, self.Vel.Y):DegRotate(math.random(-10, 10));
				MovableMan:AddParticle(GFX)
				if math.random(0, 100) < 20 then
					local extraGFX = self.CompliSoundBulletTerrainExtraGFX[CompliSoundTerrainIDs[terrainID]]:Clone()
					extraGFX.Pos = self.Pos
					extraGFX.Vel = Vector(self.Vel.X, self.Vel.Y):DegRotate(math.random(-10, 10));
					MovableMan:AddParticle(extraGFX)
				end
			else
				local GFX = self.CompliSoundBulletTerrainGFX.Impact[177]:Clone()
				GFX.Pos = self.Pos
				GFX.Vel = self.Vel
				MovableMan:AddParticle(GFX)
			end				
		end
	end
end
