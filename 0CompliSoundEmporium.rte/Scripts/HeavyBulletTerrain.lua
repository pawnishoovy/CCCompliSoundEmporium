-- Usage notes:

-- If your gun fires multiple particles, you MUST make sure only one of them has this script.
-- This means you must either fire via Lua, or via emitter. Normal Rounds firing MOPixels cannot do this.

function Create(self)

	-- Manual matching of sounds to terrainIDs.
	self.terrainSounds = {
	Impact = {[12] = CreateSoundContainer("CompliSound Heavy Bullet Impact Concrete", "0CompliSoundEmporium.rte"),
			[164] = CreateSoundContainer("CompliSound Heavy Bullet Impact Concrete", "0CompliSoundEmporium.rte"),
			[177] = CreateSoundContainer("CompliSound Heavy Bullet Impact Concrete", "0CompliSoundEmporium.rte"),
			[9] = CreateSoundContainer("CompliSound Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[10] = CreateSoundContainer("CompliSound Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[11] = CreateSoundContainer("CompliSound Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[128] = CreateSoundContainer("CompliSound Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[6] = CreateSoundContainer("CompliSound Heavy Bullet Impact Sand", "0CompliSoundEmporium.rte"),
			[8] = CreateSoundContainer("CompliSound Heavy Bullet Impact Sand", "0CompliSoundEmporium.rte"),
			[178] = CreateSoundContainer("CompliSound Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[179] = CreateSoundContainer("CompliSound Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[180] = CreateSoundContainer("CompliSound Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[181] = CreateSoundContainer("CompliSound Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[182] = CreateSoundContainer("CompliSound Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte")}}
			
	-- Manual matching of GFX to terrainIDs.
	self.terrainGFX = {
	Impact = {[12] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Concrete", "0CompliSoundEmporium.rte"),
			[164] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Concrete", "0CompliSoundEmporium.rte"),
			[177] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Concrete", "0CompliSoundEmporium.rte"),
			[9] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[10] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[11] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[128] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt", "0CompliSoundEmporium.rte"),
			[6] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Sand", "0CompliSoundEmporium.rte"),
			[8] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Sand", "0CompliSoundEmporium.rte"),
			[178] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[179] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[180] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[181] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte"),
			[182] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal", "0CompliSoundEmporium.rte")}}
			
	-- Manual matching of GFX to terrainIDs. These happen with a 20% chance.
	self.terrainExtraGFX = {
	Impact = {[12] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Concrete Extra", "0CompliSoundEmporium.rte"),
			[164] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Concrete Extra", "0CompliSoundEmporium.rte"),
			[177] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Concrete Extra", "0CompliSoundEmporium.rte"),
			[9] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt Extra", "0CompliSoundEmporium.rte"),
			[10] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt Extra", "0CompliSoundEmporium.rte"),
			[11] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt Extra", "0CompliSoundEmporium.rte"),
			[128] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Dirt Extra", "0CompliSoundEmporium.rte"),
			[6] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Sand Extra", "0CompliSoundEmporium.rte"),
			[8] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact Sand Extra", "0CompliSoundEmporium.rte"),
			[178] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal Extra", "0CompliSoundEmporium.rte"),
			[179] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal Extra", "0CompliSoundEmporium.rte"),
			[180] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal Extra", "0CompliSoundEmporium.rte"),
			[181] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal Extra", "0CompliSoundEmporium.rte"),
			[182] = CreateMOSRotating("CompliSound GFX Heavy Bullet Impact SolidMetal Extra", "0CompliSoundEmporium.rte")}}
	
end

function OnCollideWithTerrain(self, terrainID)
	if self.impactDone ~= true then
		self.impactDone = true;
		if terrainID ~= 0 then -- 0 = air
			if self.terrainSounds.Impact[terrainID] ~= nil then
				self.terrainSounds.Impact[terrainID]:Play(self.Pos);
			end
			if self.terrainGFX.Impact[terrainID] ~= nil then
				local GFX = self.terrainGFX.Impact[terrainID]:Clone()
				GFX.Pos = self.Pos
				GFX.Vel = Vector(self.Vel.X, self.Vel.Y):DegRotate(math.random(-10, 10));
				MovableMan:AddParticle(GFX)
				if math.random(0, 100) < 20 then
					local extraGFX = self.terrainExtraGFX.Impact[terrainID]:Clone()
					extraGFX.Pos = self.Pos
					extraGFX.Vel = Vector(self.Vel.X, self.Vel.Y):DegRotate(math.random(-10, 10));
					MovableMan:AddParticle(extraGFX)
				end
			else
				local GFX = self.terrainGFX.Impact[177]:Clone()
				GFX.Pos = self.Pos
				GFX.Vel = self.Vel
				MovableMan:AddParticle(GFX)
			end				
		end
	end
end
