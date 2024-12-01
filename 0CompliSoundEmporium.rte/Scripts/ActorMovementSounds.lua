-- Usage notes:

-- self.CompliSoundActorSprinting set to true will use Sprint instead of Walk sounds. It's up to you to keep track of it.
-- You can set specific impact thresholds using self.CompliSoundActorImpactLightThreshold and self.CompliSoundActorImpactHeavyThreshold in a Lua file preceding this one.
-- To play jump sounds, set self.CompliSoundActorPlayJumpSound to true for one frame. Terrain detection will be done automatically, and it will make landing sounds more consistent.

-- Callbacks available for you to use, to sync up your own foley sounds:

-- self.CompliSoundActorStepCallback
-- self.CompliSoundActorJumpCallback
-- self.CompliSoundActorLandCallback
-- self.CompliSoundActorProneCallback
-- self.CompliSoundActorCrawlCallback
-- self.CompliSoundActorImpactLightCallback
-- self.CompliSoundActorImpactHeavyCallback

require("MasterTerrainIDList")

function OnMessage(self, message, object)
	if message == "CompliSound_HeadCollisionTerrainID" then
		self.CompliSoundActorLastTerrainIDCollidedWith = object;
	end
end

function Create(self)
	self.CompliSoundActorTerrainSounds = {};

	self.CompliSoundActorTerrainSounds.Walk = {};
	self.CompliSoundActorTerrainSounds.Walk.Concrete = CreateSoundContainer("CompliSound Walk Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Walk.Dirt = CreateSoundContainer("CompliSound Walk Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Walk.Sand = CreateSoundContainer("CompliSound Walk Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Walk.SolidMetal = CreateSoundContainer("CompliSound Walk SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.Sprint = {};
	self.CompliSoundActorTerrainSounds.Sprint.Concrete = CreateSoundContainer("CompliSound Sprint Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Sprint.Dirt = CreateSoundContainer("CompliSound Sprint Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Sprint.Sand = CreateSoundContainer("CompliSound Sprint Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Sprint.SolidMetal = CreateSoundContainer("CompliSound Sprint SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.Jump = {};
	self.CompliSoundActorTerrainSounds.Jump.Concrete = CreateSoundContainer("CompliSound Jump Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Jump.Dirt = CreateSoundContainer("CompliSound Jump Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Jump.Sand = CreateSoundContainer("CompliSound Jump Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Jump.SolidMetal = CreateSoundContainer("CompliSound Jump SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.Land = {};
	self.CompliSoundActorTerrainSounds.Land.Concrete = CreateSoundContainer("CompliSound Land Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Land.Dirt = CreateSoundContainer("CompliSound Land Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Land.Sand = CreateSoundContainer("CompliSound Land Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Land.SolidMetal = CreateSoundContainer("CompliSound Land SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.Prone = {};
	self.CompliSoundActorTerrainSounds.Prone.Concrete = CreateSoundContainer("CompliSound Prone Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Prone.Dirt = CreateSoundContainer("CompliSound Prone Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Prone.Sand = CreateSoundContainer("CompliSound Prone Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Prone.SolidMetal = CreateSoundContainer("CompliSound Prone SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.Crawl = {};
	self.CompliSoundActorTerrainSounds.Crawl.Concrete = CreateSoundContainer("CompliSound Crawl Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Crawl.Dirt = CreateSoundContainer("CompliSound Crawl Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Crawl.Sand = CreateSoundContainer("CompliSound Crawl Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.Crawl.SolidMetal = CreateSoundContainer("CompliSound Crawl SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.ImpactLight = {};
	self.CompliSoundActorTerrainSounds.ImpactLight.Concrete = CreateSoundContainer("CompliSound Impact Light Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.ImpactLight.Dirt = CreateSoundContainer("CompliSound Impact Light Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.ImpactLight.Sand = CreateSoundContainer("CompliSound Impact Light Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.ImpactLight.SolidMetal = CreateSoundContainer("CompliSound Impact Light SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSounds.ImpactHeavy = {};
	self.CompliSoundActorTerrainSounds.ImpactHeavy.Concrete = CreateSoundContainer("CompliSound Impact Heavy Concrete", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.ImpactHeavy.Dirt = CreateSoundContainer("CompliSound Impact Heavy Dirt", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.ImpactHeavy.Sand = CreateSoundContainer("CompliSound Impact Heavy Sand", "0CompliSoundEmporium.rte");
	self.CompliSoundActorTerrainSounds.ImpactHeavy.SolidMetal = CreateSoundContainer("CompliSound Impact Heavy SolidMetal", "0CompliSoundEmporium.rte");
	
	self.CompliSoundActorTerrainSoundDefaultVolumeOverride = self.CompliSoundActorTerrainSoundDefaultVolumeOverride or 1.0;
	
	for soundType, soundTable in pairs(self.CompliSoundActorTerrainSounds) do
		for terrain, soundContainer in pairs(soundTable) do
			soundContainer.Pitch = self.CompliSoundActorTerrainSoundPitchOverride or 1.0;
			
		end
	end	
	
	if self.Head then
		-- Script to grab terrain collision IDs from the head as well as the torso.
		self.Head:AddScript("0CompliSoundEmporium.rte/Scripts/ActorMovementSoundsHeadScript.lua");
	end
	
	-- Cooldown timer for terrain impact sounds.
	self.CompliSoundActorImpactSoundTimer = Timer();
	-- Minimum time between terrain impact sounds.
	self.CompliSoundActorImpactSoundCooldown = 250;
	-- Impulse threshold for light impact sound playing.
	self.CompliSoundActorImpactLightThreshold = self.CompliSoundActorImpactLightThreshold or self.ImpulseDamageThreshold * 0.6;
	-- Impulse threshold for heavy impact sound playing.
	self.CompliSoundActorImpactHeavyThreshold = self.CompliSoundActorImpactHeavyThreshold or self.ImpulseDamageThreshold * 0.8;

	-- Keeping track of which foot we're stepping with and should run calculations on. Resets when not walking, because you always step with your FG Foot first.
	self.CompliSoundActorFootIterator= 0;
	-- Whether BG and FG foot are contacting ground.
    self.CompliSoundActorFootContacts = {false, false};
	-- Timers per foot to avoid noise.
	self.CompliSoundActorFootTimers = {Timer(), Timer()};
	-- Delay before ground is considered contacted.
	self.CompliSoundActorAntiFootNoiseDelay = 100;
	-- Delay after jumping before a landing sound can play. Prevents insta-land sounds when jumping.
	self.CompliSoundActorAntiJumpNoiseTimer = Timer();
	-- Whether we are in the air or not.
	self.CompliSoundActorWasInAir = false;
	-- Timer to invalidate being in the air.
	self.CompliSoundActorWasInAirTimer = Timer();
	-- Delay before invalidating being in air.
	self.CompliSoundActorWasInAirInvalidateTime = 50;
	-- Generic timer to avoid playing sounds generally too quick one after another.
	self.CompliSoundActorMoveSoundTimer = Timer();
end

function OnStride(self)
	local doStepSound = false;
	local terrainID;
	local startPos;

	if self.BGFoot and self.FGFoot then
		startPos = self.CompliSoundActorFootIterator == 0 and self.BGFoot.Pos or self.FGFoot.Pos
		self.CompliSoundActorFootIterator = (self.CompliSoundActorFootIterator + 1) % 2
	elseif self.BGFoot then
		startPos = self.BGFoot.Pos
	elseif self.FGFoot then
		startPos = self.FGFoot.Pos
	end
	
	local pos = Vector(0, 0);
	local ray = SceneMan:CastObstacleRay(startPos, Vector(0, 9), pos, Vector(0, 0), self.ID, self.Team, 0, 3);	
	if ray ~= -1 then
		terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
		
		if terrainID ~= -1 then
			if not CompliSoundTerrainIDs[terrainID] then
				terrainID = 177; -- Default to concrete
			end
		
			if self.CompliSoundActorSprinting then
				if self.CompliSoundActorTerrainSounds.Sprint[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundActorTerrainSounds.Sprint[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			else
				if self.CompliSoundActorTerrainSounds.Walk[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundActorTerrainSounds.Walk[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			end
			
			if self.CompliSoundActorStepCallback then
				self.CompliSoundActorStepCallback(self);
			end			
		end
	end
end

function OnCollideWithTerrain(self, terrainID)
	-- We can't collide with air, so no ~= 0 check here
	if CompliSoundTerrainIDs[terrainID] == nil then
		terrainID = 177; -- Default to concrete
	end
	if self.CompliSoundActorImpactSoundTimer:IsPastSimMS(self.CompliSoundActorImpactSoundCooldown) and not self.CompliSoundActorSprinting then
		if self.CompliSoundActorProning and not self.CompliSoundProneSoundPlayed then
			self.CompliSoundProneSoundPlayed = true;
			if self.CompliSoundActorTerrainSounds.Prone[CompliSoundTerrainIDs[terrainID]] ~= nil then
				self.CompliSoundActorTerrainSounds.Prone[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
			end
			self.CompliSoundActorImpactSoundTimer:Reset();
			if self.CompliSoundActorProneCallback then
				self.CompliSoundActorProneCallback(self);
			end
		end
	end
	
	self.CompliSoundActorLastTerrainIDCollidedWith = terrainID;
end

function ThreadedUpdate(self)
	local isPlayerControlled = self:IsPlayerControlled();
	
	for soundType, soundTable in pairs(self.CompliSoundActorTerrainSounds) do
		for terrain, soundContainer in pairs(soundTable) do
			soundContainer.Pos = self.Pos;
			soundContainer.Volume = self.CompliSoundActorTerrainSoundDefaultVolumeOverride
			if self.CompliSoundActorCrouching then
				soundContainer.Volume = soundContainer.Volume * 0.6;
			end
		end
	end

	local controller = self:GetController();
	self.CompliSoundActorCrouching = controller:IsState(Controller.BODY_WALKCROUCH)
	self.CompliSoundActorProning = controller:IsState(Controller.BODY_PRONE)
	self.CompliSoundActorSprinting = self.MovementState == Actor.RUN;
	self.CompliSoundActorMoving = controller:IsState(Controller.MOVE_LEFT) or controller:IsState(Controller.MOVE_RIGHT);
	
	local lastSteppedTerrainID;

	if isPlayerControlled or not self.AI then
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
				if landTerrainID ~= 0 then
					if not CompliSoundTerrainIDs[landTerrainID] then
						landTerrainID = 177; -- Default to concrete
					end
					if self.CompliSoundActorTerrainSounds.Land[CompliSoundTerrainIDs[landTerrainID]] then
						self.CompliSoundActorTerrainSounds.Land[CompliSoundTerrainIDs[landTerrainID]]:Play(self.Pos);
					end
				end
				self.CompliSoundActorMoveSoundTimer:Reset();
				if self.CompliSoundActorLandCallback then
					self.CompliSoundActorLandCallback(self);
				end
			end
		end
	end
	
	if not self.CompliSoundActorMoving then
		self.CompliSoundActorFootIterator = 0;
	end
	
	if self.CompliSoundActorWasInAir or self.CompliSoundActorIsJumping then
		if (isPlayerControlled and self.CompliSoundActorFootContacts[1] == true or self.CompliSoundActorFootContacts[2] == true) and self.CompliSoundActorAntiJumpNoiseTimer:IsPastSimMS(100) then
			self.CompliSoundActorWasInAir = false;
			self.CompliSoundActorIsJumping = false;
			if self.Vel.Y > 0 and self.CompliSoundActorMoveSoundTimer:IsPastSimMS(500) then
				local landTerrainID = lastSteppedTerrainID;
				if landTerrainID ~= 0 then
					if not CompliSoundTerrainIDs[landTerrainID] then
						landTerrainID = 177; -- Default to concrete
					end
					if self.CompliSoundActorTerrainSounds.Land[CompliSoundTerrainIDs[landTerrainID]] then
						self.CompliSoundActorTerrainSounds.Land[CompliSoundTerrainIDs[landTerrainID]]:Play(self.Pos);
					end
				end
				self.CompliSoundActorMoveSoundTimer:Reset();
				if self.CompliSoundActorLandCallback then
					self.CompliSoundActorLandCallback(self);
				end
			end
		end
	end
	
	if not (self.CompliSoundActorProning) and self.CompliSoundProneSoundPlayed then
		self.CompliSoundProneSoundPlayed = false;
	elseif self.CompliSoundActorProning and self.CompliSoundActorMoving and self.CompliSoundProneSoundPlayed and not self.CompliSoundActorSprinting then
		if self.CompliSoundActorMoveSoundTimer:IsPastSimMS(800) then
			local pos = Vector(0, 0);
			SceneMan:CastObstacleRay(self.Pos, Vector(0, 20), pos, Vector(0, 0), self.ID, self.Team, 0, 2);				
			local terrainID = SceneMan:GetTerrMatter(pos.X, pos.Y)
			if terrainID ~= 0 then
				if not CompliSoundTerrainIDs[terrainID] then
					terrainID = 177; -- Default to concrete
				end
				if self.CompliSoundActorTerrainSounds.Crawl[CompliSoundTerrainIDs[terrainID]] ~= nil then
					self.CompliSoundActorTerrainSounds.Crawl[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
			end
			self.CompliSoundActorMoveSoundTimer:Reset();
			if self.CompliSoundActorCrawlCallback then
				self.CompliSoundActorCrawlCallback(self);
			end
		end
	end
	
	if self.CompliSoundActorPlayJumpSound then
		self.CompliSoundActorPlayJumpSound = false;
		local jumpTerrainID = lastSteppedTerrainID;
		if jumpTerrainID ~= 0 then
			if not CompliSoundTerrainIDs[jumpTerrainID] then
				jumpTerrainID = 177; -- Default to concrete
			end
			if self.CompliSoundActorTerrainSounds.Jump[CompliSoundTerrainIDs[jumpTerrainID]] then
				self.CompliSoundActorTerrainSounds.Jump[CompliSoundTerrainIDs[jumpTerrainID]]:Play(self.Pos);
			end
		end
		self.CompliSoundActorAntiJumpNoiseTimer:Reset();
		self.CompliSoundActorIsJumping = true;
		-- Sure, theoretically you're already telling THIS script to jump, but... neater this way.
		if self.CompliSoundActorJumpCallback then
			self.CompliSoundActorJumpCallback(self);
		end
	end
	
	
	if self.CompliSoundActorImpactSoundTimer:IsPastSimMS(self.CompliSoundActorImpactSoundCooldown) then
		local terrainID = self.CompliSoundActorLastTerrainIDCollidedWith;
		if terrainID ~= 0 then -- This shouldn't be possible, but always good to sanity check
			if not CompliSoundTerrainIDs[terrainID] then
				terrainID = 177; -- Default to concrete
			end
			if self.Status > 0 and self.TravelImpulse.Magnitude > self.CompliSoundActorImpactHeavyThreshold then
				if self.CompliSoundActorTerrainSounds.ImpactHeavy[CompliSoundTerrainIDs[terrainID]] then
					self.CompliSoundActorTerrainSounds.ImpactHeavy[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
				self.CompliSoundActorImpactSoundTimer:Reset();
				if self.CompliSoundActorImpactHeavyCallback then
					self.CompliSoundActorImpactHeavyCallback(self);
				end
			elseif self.TravelImpulse.Magnitude > self.CompliSoundActorImpactLightThreshold then
				if self.CompliSoundActorTerrainSounds.ImpactLight[CompliSoundTerrainIDs[terrainID]] then
					self.CompliSoundActorTerrainSounds.ImpactLight[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
				end
				self.CompliSoundActorImpactSoundTimer:Reset();
				if self.CompliSoundActorImpactLightCallback then
					self.CompliSoundActorImpactLightCallback(self);
				end
			end
		end
	end
end