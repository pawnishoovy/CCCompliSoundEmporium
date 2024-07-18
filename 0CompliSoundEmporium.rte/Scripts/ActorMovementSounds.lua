-- Usage notes:

-- self.CompliSoundActorSprinting set to true will use Sprint instead of Walk sounds. It's up to you to keep track of it.
-- You can set specific impact thresholds using self.CompliSoundActorImpactLightThreshold and self.CompliSoundActorImpactHeavyThreshold in a Lua file preceding this one.
-- To play jump sounds, set self.CompliSoundActorPlayJumpSound to true for one frame. Terrain detection will be done automatically, and it will make landing sounds more consistent.

require("MasterTerrainIDList")

function Create(self)
	self.CompliSoundActorWalkSounds = {};
	self.CompliSoundActorWalkSounds.Concrete = CreateSoundContainer("CompliSound Walk Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorWalkSounds.Dirt = CreateSoundContainer("CompliSound Walk Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorWalkSounds.Sand = CreateSoundContainer("CompliSound Walk Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorWalkSounds.SolidMetal = CreateSoundContainer("CompliSound Walk SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorSprintSounds = {};
	self.CompliSoundActorSprintSounds.Concrete = CreateSoundContainer("CompliSound Sprint Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorSprintSounds.Dirt = CreateSoundContainer("CompliSound Sprint Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorSprintSounds.Sand = CreateSoundContainer("CompliSound Sprint Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorSprintSounds.SolidMetal = CreateSoundContainer("CompliSound Sprint SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorJumpSounds = {};
	self.CompliSoundActorJumpSounds.Concrete = CreateSoundContainer("CompliSound Jump Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorJumpSounds.Dirt = CreateSoundContainer("CompliSound Jump Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorJumpSounds.Sand = CreateSoundContainer("CompliSound Jump Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorJumpSounds.SolidMetal = CreateSoundContainer("CompliSound Jump SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorLandSounds = {};
	self.CompliSoundActorLandSounds.Concrete = CreateSoundContainer("CompliSound Land Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorLandSounds.Dirt = CreateSoundContainer("CompliSound Land Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorLandSounds.Sand = CreateSoundContainer("CompliSound Land Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorLandSounds.SolidMetal = CreateSoundContainer("CompliSound Land SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorProneSounds = {};
	self.CompliSoundActorProneSounds.Concrete = CreateSoundContainer("CompliSound Prone Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorProneSounds.Dirt = CreateSoundContainer("CompliSound Prone Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorProneSounds.Sand = CreateSoundContainer("CompliSound Prone Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorProneSounds.SolidMetal = CreateSoundContainer("CompliSound Prone SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorCrawlSounds = {};
	self.CompliSoundActorCrawlSounds.Concrete = CreateSoundContainer("CompliSound Crawl Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorCrawlSounds.Dirt = CreateSoundContainer("CompliSound Crawl Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorCrawlSounds.Sand = CreateSoundContainer("CompliSound Crawl Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorCrawlSounds.SolidMetal = CreateSoundContainer("CompliSound Crawl SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorImpactLightSounds = {};
	self.CompliSoundActorImpactLightSounds.Concrete = CreateSoundContainer("CompliSound Impact Light Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorImpactLightSounds.Dirt = CreateSoundContainer("CompliSound Impact Light Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorImpactLightSounds.Sand = CreateSoundContainer("CompliSound Impact Light Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorImpactLightSounds.SolidMetal = CreateSoundContainer("CompliSound Impact Light SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorImpactHeavySounds = {};
	self.CompliSoundActorImpactHeavySounds.Concrete = CreateSoundContainer("CompliSound Impact Heavy Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorImpactHeavySounds.Dirt = CreateSoundContainer("CompliSound Impact Heavy Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorImpactHeavySounds.Sand = CreateSoundContainer("CompliSound Impact Heavy Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorImpactHeavySounds.SolidMetal = CreateSoundContainer("CompliSound Impact Heavy SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorImpactSoundTimer = Timer();
	self.CompliSoundActorImpactSoundCooldown = 250;
	self.CompliSoundActorImpactLightThreshold = self.CompliSoundActorImpactLightThreshold or self.ImpulseDamageThreshold * 0.6;
	self.CompliSoundActorImpactHeavyThreshold = self.CompliSoundActorImpactHeavyThreshold or self.ImpulseDamageThreshold * 0.25;

	self.CompliSoundActorFootIterator= 0;
    self.CompliSoundActorFootContacts = {false, false}
	self.CompliSoundActorFootTimers = {Timer(), Timer()}
	self.CompliSoundActorAntiFootNoiseDelay = 100
	self.CompliSoundActorAntiJumpNoiseTimer = Timer();
	self.CompliSoundActorWasInAir = false;
	self.CompliSoundActorWasInAirTimer = Timer();
	self.CompliSoundActorWasInAirInvalidateTime = 50;
	self.CompliSoundActorMoveSoundTimer = Timer();
end

function OnStride(self)
	local doStepSound = false;
	local terrainID;

	if self.BGFoot and self.FGFoot then
		local startPos = self.CompliSoundActorFootIterator == 0 and self.BGFoot.Pos or self.FGFoot.Pos
		self.CompliSoundActorFootIterator = (self.CompliSoundActorFootIterator + 1) % 2
		
		local pos = Vector(0, 0);
		SceneMan:CastObstacleRay(startPos, Vector(0, 9), pos, Vector(0, 0), self.ID, self.Team, 0, 3);				
		terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
		
		if not CompliSoundTerrainIDs[terrainID] and terrainID ~= 0 then
			terrainID = 177; -- Default to concrete
		end
		
		if terrainID ~= 0 then -- 0 = air
			doStepSound = true;
		end
	elseif self.BGFoot then
		local startPos = self.BGFoot.Pos
		
		local pos = Vector(0, 0);
		SceneMan:CastObstacleRay(startPos, Vector(0, 9), pos, Vector(0, 0), self.ID, self.Team, 0, 3);				
		terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
		
		if terrainID ~= 0 then -- 0 = air
			doStepSound = true;
		end
	elseif self.FGFoot then
		local startPos = self.FGFoot.Pos
		
		local pos = Vector(0, 0);
		SceneMan:CastObstacleRay(startPos, Vector(0, 9), pos, Vector(0, 0), self.ID, self.Team, 0, 3);				
		terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
		
		if terrainID ~= 0 then -- 0 = air
			doStepSound = true;
		end	
	end
	
	if doStepSound then
		if self.CompliSoundActorSprinting then
			if self.CompliSoundActorWalkSounds[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundActorWalkSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		else
			if self.CompliSoundActorWalkSounds[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundActorWalkSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
		end
	end
end

function OnCollideWithTerrain(self, terrainID)
	if CompliSoundTerrainIDs[terrainID] == nil then
		terrainID = 177; -- Default to concrete
	end
	if self.CompliSoundActorImpactSoundTimer:IsPastSimMS(self.CompliSoundActorImpactSoundCooldown) then
		if self.CompliSoundActorCrouching and self.CompliSoundActorMoving and not self.CompliSoundProneSoundPlayed then
			self.CompliSoundProneSoundPlayed = true;
			self.CompliSoundActorProneSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			self.CompliSoundActorImpactSoundTimer:Reset();
		end
	end
end

function ThreadedUpdate(self)
	local controller = self:GetController();
	self.CompliSoundActorCrouching = controller:IsState(Controller.BODY_CROUCH)
	self.CompliSoundActorMoving = controller:IsState(Controller.MOVE_LEFT) or controller:IsState(Controller.MOVE_RIGHT);
	
	local lastSteppedTerrainID;

	if self:IsPlayerControlled() then
		if self.Vel.Y > 10 or (self.Vel.Y > 5 and self.Vel.Magnitude > 10) then
			self.CompliSoundActorWasInAir = true;
			self.CompliSoundActorWasInAirTimer:Reset();
		elseif self.CompliSoundActorWasInAirTimer:IsPastSimMS(self.CompliSoundActorWasInAirInvalidateTime) then
			self.CompliSoundActorWasInAir = false;
		end
		
		-- Check a position under each foot to approximate foot contact with land
		for i = 1, 2 do
			local foot = nil
			if i == 1 then
				foot = self.FGFoot 
			else
				foot = self.BGFoot 
			end

			if foot ~= nil then
				local footPos = foot.Pos				
				local mat = nils
				local pos = Vector(0, 0);
				local ray = SceneMan:CastObstacleRay(footPos, Vector(0, 5), pos, Vector(0, 0), self.ID, self.Team, 0, 1);
				if ray ~= -1 then
					terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
					if terrainID ~= 0 then
						lastSteppedTerrainID = terrainID;
						mat = SceneMan:GetMaterialFromID(lastSteppedTerrainID)
					end
				end
				
				local movement = (controller:IsState(Controller.MOVE_LEFT) == true or controller:IsState(Controller.MOVE_RIGHT) == true or self.Vel.Magnitude > 3)
				if mat ~= nil then
					if self.CompliSoundActorFootContacts[i] == false then
						self.CompliSoundActorFootContacts[i] = true
						if self.CompliSoundActorFootTimers[i]:IsPastSimMS(self.CompliSoundActorAntiFootNoiseDelay) and movement then																	
							self.CompliSoundActorFootTimers[i]:Reset()
						end
					end
				else
					if self.CompliSoundActorFootContacts[i] == true then
						self.CompliSoundActorFootContacts[i] = false
						if self.CompliSoundActorFootTimers[i]:IsPastSimMS(self.CompliSoundActorAntiFootNoiseDelay) and movement then
							self.CompliSoundActorFootTimers[i]:Reset()
						end
					end
				end
			end
		end
	else -- AI already is aware of whether we're flying or not, make use of it
		if self.AI.flying == true and self.CompliSoundActorWasInAir == false then
			self.CompliSoundActorWasInAir = true;
		elseif self.AI.flying == false and self.CompliSoundActorWasInAir == true then
			self.CompliSoundActorWasInAir = false;
			if self.CompliSoundActorMoveSoundTimer:IsPastSimMS(500) then
				local landTerrainID = lastSteppedTerrainID;
				if lastSteppedTerrainID ~= 0 then
					if self.CompliSoundActorLandSounds[CompliSoundTerrainIDs[lastSteppedTerrainID]] == nil then
						landTerrainID = 177; -- Default to concrete
					end
					self.CompliSoundActorLandSounds[CompliSoundTerrainIDs[landTerrainID]]:Play(self.Pos);
				end
				self.CompliSoundActorMoveSoundTimer:Reset();
			end
		end
	end
	
	if not self.CompliSoundActorMoving then
		self.CompliSoundActorFootIterator = 0;
	end
	
	if self.CompliSoundActorWasInAir or self.CompliSoundActorIsJumping then
		if (self:IsPlayerControlled() and self.CompliSoundActorFootContacts[1] == true or self.CompliSoundActorFootContacts[2] == true) and self.CompliSoundActorAntiJumpNoiseTimer:IsPastSimMS(100) then
			self.CompliSoundActorWasInAir = false;
			self.CompliSoundActorIsJumping = false;
			if self.Vel.Y > 0 and self.CompliSoundActorMoveSoundTimer:IsPastSimMS(500) then
				local landTerrainID = lastSteppedTerrainID;
				if lastSteppedTerrainID ~= 0 then
					if self.CompliSoundActorLandSounds[CompliSoundTerrainIDs[lastSteppedTerrainID]] == nil then
						landTerrainID = 177; -- Default to concrete
					end
					self.CompliSoundActorLandSounds[CompliSoundTerrainIDs[landTerrainID]]:Play(self.Pos);
				end
				self.CompliSoundActorMoveSoundTimer:Reset();
			end
		end
	end
	
	if not (self.CompliSoundActorCrouching) and self.CompliSoundProneSoundPlayed then
		self.CompliSoundProneSoundPlayed = false;
	elseif self.CompliSoundActorCrouching and self.CompliSoundActorMoving and self.CompliSoundProneSoundPlayed then
		if self.CompliSoundActorMoveSoundTimer:IsPastSimMS(800) then
			local pos = Vector(0, 0);
			SceneMan:CastObstacleRay(self.Pos, Vector(0, 20), pos, Vector(0, 0), self.ID, self.Team, 0, 2);				
			local terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
			if self.CompliSoundActorCrawlSounds[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundActorCrawlSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
			self.CompliSoundActorMoveSoundTimer:Reset();
		end
	end
	
	if self.CompliSoundActorPlayJumpSound then
		self.CompliSoundActorPlayJumpSound = false;
		local jumpTerrainID = lastSteppedTerrainID;
		if lastSteppedTerrainID ~= 0 then
			if self.CompliSoundActorJumpSounds[CompliSoundTerrainIDs[lastSteppedTerrainID]] == nil then
				jumpTerrainID = 177; -- Default to concrete
			end
			self.CompliSoundActorJumpSounds[CompliSoundTerrainIDs[jumpTerrainID]]:Play(self.Pos);
		end
		self.CompliSoundActorAntiJumpNoiseTimer:Reset();
		self.CompliSoundActorIsJumping = true;
	end
	
	
	if self.CompliSoundActorImpactSoundTimer:IsPastSimMS(self.CompliSoundActorImpactSoundCooldown) then
		if self.Status > 0 and self.TravelImpulse.Magnitude > self.CompliSoundActorImpactHeavyThreshold then
			self.CompliSoundActorImpactHeavySounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			self.CompliSoundActorImpactSoundTimer:Reset();
		elseif self.TravelImpulse.Magnitude > self.CompliSoundActorImpactLightThreshold then
			self.CompliSoundActorImpactLightSounds[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			self.CompliSoundActorImpactSoundTimer:Reset();
		end
	end

end