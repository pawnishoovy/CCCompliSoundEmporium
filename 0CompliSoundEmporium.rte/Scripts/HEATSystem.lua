function Create(self)

	-----------------
	----------------- HEAT system
	-----------------
	
	-- Please refer to the HEATStats for usage information.
	-- These variables are all commented so you can meddle with them in callbacks,
	-- but simple usage doesn't require you to know anything in here.
	
	-----------------
	----------------- Utility
	-----------------
	
	-- Identifier, so other scripts know we're a HEATSystem gun.
	self:SetNumberValue("HEAT_Identifier", 1);

	-- Actor holding us.
	self.HEATParent = nil;
	-- Whether we set the actor holding us or not.
	self.HEATParentSet = false;
	-- Last saved Age of us. Used to check if we were hidden away in an inventory or otherwise disabled from the simulation for a while.
	self.HEATLastAge = self.Age
	-- Our HFLipped last frame. Used to prevent rotational animation from flipping out.
	self.HEATLastHFlipped = self.HFlipped
	
	-- Particle utility.
	self.HEATParticleUtility = require("Scripts/Utility/ParticleUtility");
	
	-----------------
	----------------- Original values
	-----------------
	
	-- Original SharpLength.
	self.HEATOriginalSharpLength = self.SharpLength
	-- Original StanceOffset.
	self.HEATOriginalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	-- Original SharpStanceOffset.
	self.HEATOriginalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y)
	-- Original SupportOffset.
	self.HEATOriginalSupportOffset = Vector(self.SupportOffset.X, self.SupportOffset.Y)
	
	-----------------
	----------------- Animation
	-----------------
	
	-- Our current rotation.
	self.HEATRotation = 0
	-- The rotation we want to get to.
	self.HEATRotationTarget = 0
	-- Manual addition on top of RotationTarget. Doesn't override anything, letting you offset all rotations by this amount.
	self.HEATRotationTargetManualAddition = 0;
	-- Override for RotationTarget, to ignore reloads or set a new default (but not ignore recoil and angular velocity)
	self.HEATRotationTargetOverride = nil;
	-- The speed at which we rotate towards our RotationTarget.
	self.HEATRotationSpeed = 9
	-- Horizontal offset to SupportOffset, used for transient "kick" effects.
	self.HEATHorizontalAnim = 0
	-- Vertical offset to SupportOffset, used for transient "kick" effects.
	self.HEATVerticalAnim = 0
	-- Rotational "velocity" with which to affect our Rotation, used for transient "kick" effects.
	self.HEATAngVel = 0
	-- Adds rotational velocity manually. Make sure to only set it for one frame at a time unless you want the rotation to go crazy.
	self.HEATAngVelManualAddition = 0
	-- Our RotAngle last frame.
	self.HEATLastRotAngle = self.RotAngle
	-- Persistent frame to set, overriding fire animation, but not overriding reload animation.
	-- Used in the case of locking back, dropping guns mid-reload, etc.
	self.HEATPersistentFrame = nil;
	-- StanceOffset used during reloading.
	self.HEATReloadStanceOffset = Vector(0, 0);
	-- Target we want to get to for our ReloadStanceOffset.
	self.HEATReloadStanceOffsetTarget = Vector(0, 0)
	-- Speed at which we get to our ReloadSupportOffset target.
	self.HEATReloadSupportOffsetSpeed = 16
	-- Target we want to get to for our ReloadSupportOffset.
	self.HEATReloadSupportOffsetTarget = Vector(0, 0);
	
	-----------------
	----------------- Reload
	-----------------	
	
	-- Timer for the reload system.
	self.HEATReloadTimer = Timer();
	-- Whether we expended all rounds before reloading. Reset upon reload end.
	self.HEATEmptyReload = false;
	-- Whether to engage the staged reload system without actually reloading. Used for pump-actions, bolt-actions, etc.
	self.HEATNonReloadStaging = false;
	-- Whether we've done the enterPhaseCallback this phase or not. Shouldn't be messed with.
	self.HEATEnterPhaseCallbackDone = false;
	-- Whether we've played the prepareSound this phase or not. Shouldn't be messed with.
	self.HEATPrepareSoundPlayed = false;
	-- Whether the phase finishing logic was done this phase or not. Shouldn't be messed with.
	self.HEATPhaseFinishDone = false;
	-- Whether the fire button was pressed this reload phase. Doesn't do anything automatically except in the case of shotgun reload loops.
	self.HEATManualInterruptionAttempted = false;
	-- The reload phase we're currently at.
	self.HEATCurrentReloadPhase = 1;
	-- Active data for our current phase.
	self.HEATCurrentReloadPhaseData = nil;
	-- Phase to set to return to later if our current reload is interrupted.
	self.HEATReloadPhaseOnInterrupt = nil;
	-- Whether we've had our reload interrupted previously, and have had to set a PhaseOnInterrupt.
	self.HEATWasInterrupted = false;
	-- Override for the next phase to progress to. Ignores all other logic except ForceEndReload.
	self.HEATReloadPhaseOverride = nil;
	-- Forces the reload to end upon current phase exit no matter what.
	self.HEATForceEndReload = false;
	-- Whether to spawn a casing on the next phase with spawnCasing or not. Set to true every time the gun fires, set to false when a casing is spawned.
	self.HEATToSpawnCasing = false;
	-- Internal ammo counter used in the case of shotgun-style reloads.
	-- Grabs it from our magazine if we have one and it's different from the FullMagazineRoundCount, but the saved value overrides it if it exists.
	self.HEATAmmoCounter = (self.Magazine and self.Magazine.RoundCount ~= self.HEATFullMagazineRoundCount) and self.Magazine.RoundCount or self.HEATFullMagazineRoundCount;
	if self:NumberValueExists("heatAmmoCounter") then
		self.HEATAmmoCounter = self:GetNumberValue("heatAmmoCounter");
		self:RemoveNumberValue("heatAmmoCounter");
	end
	-- The time it should take us to do a reload with rounds still in the magazine.
	-- Relevant only to the progress bar.
	self.HEATTotalFullReloadTime = self.HEATTotalFullReloadTimeOverride or nil;
	-- The time it should take us to do a reload without any rounds in the magazine.
	-- Relevant only to the progress bar.
	self.HEATTotalEmptyReloadTime = self.HEATTotalEmptyReloadTimeOverride or nil;
	-- If there weren't any Overrides set in the Stats, then autocalculate best guesses.
	if not self.HEATTotalFullReloadTime then
		-- I know 50 here is super arbitrary, but having it at 0 or 1 has the game sometimes manage to prematurely end a reload. The autocalculation isn't perfect.
		-- This is just a safety buffer.
		local totalFullTime = 50;
		for i = 1, #self.HEATReloadPhases do
			totalFullTime = totalFullTime + self.HEATReloadPhases[i].prepareDelay + self.HEATReloadPhases[i].afterDelay;
			if self.HEATReloadPhases[i].endIfNotEmptyReload then
				break;
			end
		end
		self.HEATTotalFullReloadTime = totalFullTime + 1;
	end
	if not self.HEATTotalEmptyReloadTime then
		local totalEmptyTime = 50;
		for i = 1, #self.HEATReloadPhases do
			totalEmptyTime = totalEmptyTime + self.HEATReloadPhases[i].prepareDelay + self.HEATReloadPhases[i].afterDelay;
		end	
		self.HEATTotalEmptyReloadTime = totalEmptyTime + 1;
	end
	self.BaseReloadTime = self.HEATTotalFullReloadTime;
	-- Function to end an ongoing reload and reset values. Here to avoid dupe code.
	self.HEATEndReload = function (self)
		self.HEATCurrentReloadPhase = 1;
		self.HEATNonReloadStaging = false;
		self.HEATReloadStanceOffsetTarget = Vector(0, 0);
		self.HEATReloadSupportOffsetTarget = Vector(0, 0);
		
		self.HEATReloadPhaseOnInterrupt = nil;
		self.HEATPersistentFrame = nil;
		
		self.HEATManualInterruptionAttempted = false;
		
		self.HEATToSpawnCasing = false;
		
		self.BaseReloadTime = 0;	
	end
		
	-----------------
	----------------- Delayed fire
	-----------------		
		
	-- Timer used for an extra rate-of-fire-dependent delay to trying to activate DelayedFire.
	self.HEATFireDelayTimer = Timer();
	-- Whether we are activated and about to try to fire.
	self.HEATDelayedFire = false
	-- Timer for the DelayedFire system.
	self.HEATDelayedFireTimer = Timer();
	-- Some sort of logical variable for the DelayedFire system. I honestly don't remember, but it has to exist.
	self.HEATDelayedFireActivated = false
	-- Used to disable delaying further firing after our first shot, in the case of full-auto weapons.
	self.HEATDelayedFirstShot = true;
	
	-----------------
	----------------- Firing animation
	-----------------
	
	-- Timer for the firing animation.
	self.HEATFiringAnimationTimer = Timer();
	
	-----------------
	----------------- Recoil
	-----------------
	
	-- Later filled with total rotation.
	self:SetNumberValue("HEAT_CurrentRecoil", 0);
	
	-- Mathemagical recoil variable. Shouldn't be messed with.
	self.HEATRecoilAcc = 0
	-- Mathemagical recoil variable. Shouldn't be messed with.
	self.HEATRecoilStr = 0
	
	-- Factor to shift recoil angle, simulating AI counteracting the recoil. Eventually negates recoil,
	-- but the recoil respect actor script won't realistically let it turn any gun into a laser beam.
	self.HEATRecoilAIHomingFactor = 0;
	
	-----------------
	----------------- Miscellaneous
	-----------------	
	
	-- Helper function.
	self.HEATCheckIfPointIsIndoors = function (self, point)
		if point then
			local outdoorRays = 0;
			local indoorRays = 0;
			local bigIndoorRays = 0;
			local rayThreshold = 2;

			local Vector2 = Vector(0,-700); -- straight up
			local Vector2Left = Vector(0,-700):RadRotate(45*(math.pi/180));
			local Vector2Right = Vector(0,-700):RadRotate(-45*(math.pi/180));			
			local Vector2SlightLeft = Vector(0,-700):RadRotate(22.5*(math.pi/180));
			local Vector2SlightRight = Vector(0,-700):RadRotate(-22.5*(math.pi/180));		
			local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
			local Vector4 = Vector(0,0); -- dont need this but is needed as an arg

			local ray = SceneMan:CastObstacleRay(point, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			local rayRight = SceneMan:CastObstacleRay(point, Vector2Right, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			local rayLeft = SceneMan:CastObstacleRay(point, Vector2Left, Vector3, Vector4, self.RootID, self.Team, 128, 7);			
			local raySlightRight = SceneMan:CastObstacleRay(point, Vector2SlightRight, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			local raySlightLeft = SceneMan:CastObstacleRay(point, Vector2SlightLeft, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			
			local rayTable = {ray, rayRight, rayLeft, raySlightRight, raySlightLeft};
			
			for _, rayLength in ipairs(rayTable) do
				if rayLength < 0 then
					outdoorRays = outdoorRays + 1;
				elseif rayLength > 170 then
					bigIndoorRays = bigIndoorRays + 1;
				else
					indoorRays = indoorRays + 1;
				end
			end
			
			if outdoorRays >= rayThreshold then
				return false;
			else
				return true;
			end
		else
			print("ERROR: HEATSystem was asked to check a point for indoorness, but was not given a point!");
		end
	end
	
	-- Normal creation has OnAttach happen properly, but reloading scripts clears the Lua state (and thus the parent) without running OnAttach again, but this will run and fix it
	local rootParent = self:GetRootParent();
	if IsAHuman(rootParent) then
		self.HEATParent = ToAHuman(rootParent);
		self.HEATParentController = self.HEATParent:GetController();
		if not self.HEATParent:HasScript("0CompliSoundEmporium.rte/Scripts/HEATActorRecoilRespect.lua") then
			self.HEATParent:AddScript("0CompliSoundEmporium.rte/Scripts/HEATActorRecoilRespect.lua");
		end
	end
end

function OnAttach(self, newParent)
	if IsAHuman(newParent:GetRootParent()) then
		self.HEATParent = ToAHuman(newParent:GetRootParent());
		self.HEATParentController = self.HEATParent:GetController();
		if not self.HEATParent:HasScript("0CompliSoundEmporium.rte/Scripts/HEATActorRecoilRespect.lua") then
			self.HEATParent:AddScript("0CompliSoundEmporium.rte/Scripts/HEATActorRecoilRespect.lua");
		end
	end
end

function OnDetach(self)
	self.HEATParent = nil;
	self.HEATParentController = nil;
end

function ThreadedUpdate(self)
	--PrimitiveMan:DrawLinePrimitive(self.MuzzlePos, self.MuzzlePos + Vector(300 * self.FlipFactor, 0):RadRotate(self.RotAngle), 133);

	self.Frame = 0;
	self.HEATRotationTarget = 0
	
    -- Smoothing
    local min_value = -math.pi;
    local max_value = math.pi;
    local value = self.RotAngle - self.HEATLastRotAngle
    local result;
    local ret = 0
    
    local range = max_value - min_value;
    if range <= 0 then
        result = min_value;
    else
        ret = (value - min_value) % range;
        if ret < 0 then ret = ret + range end
        result = ret + min_value;
    end
    
    self.HEATLastRotAngle = self.RotAngle
    self.HEATAngVel = (result / TimerMan.DeltaTimeSecs) * self.FlipFactor
	self.HEATAngVel = self.HEATAngVel + self.HEATAngVelManualAddition;
    
    if self.HEATLastHFlipped ~= nil then
        if self.HEATLastHFlipped ~= self.HFlipped then
            self.HEATLastHFlipped = self.HFlipped
            self.HEATAngVel = 0
        end
    end
	if self.Age > (self.HEATLastAge + TimerMan.DeltaTimeSecs * 2000) then
		if self.HEATDelayedFire then
			self.HEATDelayedFire = false
		end
		self.HEATFireDelayTimer:Reset()
		
		self.HEATCurrentReloadPhaseData = nil;
		self.HEATPrepareSoundPlayed = false;
		self.HEATPhaseFinishDone = false;
		
		self.HEATReloadTimer:Reset();
		if self.HEATReloadPhaseOnInterrupt then
			self.HEATCurrentReloadPhase = self.HEATReloadPhaseOnInterrupt;
			self.HEATReloadPhaseOnInterrupt = nil;
			self.HEATWasInterrupted = true;
		end
	
		self.HEATCurrentReloadPhaseData = nil;
		self.HEATPrepareSoundPlayed = false;
		self.HEATPhaseFinishDone = false;
			
	end
	self.HEATLastAge = self.Age + 0
	
	if self.useHEATFiringAnimation then
		local f = math.max(1 - math.min((self.HEATFiringAnimationTimer.ElapsedSimTimeMS) / 200, 1), 0)
		self.Frame = math.floor(f * self.HEATFiringAnimationEndFrame + 0.55);
		if self.HEATEmptyReload and self.HEATLockBackOnEmpty and self.Frame == self.HEATFiringAnimationEndFrame then
			self.HEATPersistentFrame = self.HEATFiringAnimationEndFrame;
		end
	end
	
	self.Frame = self.HEATPersistentFrame or self.Frame;
	
	-- Reload system
	
	if self.useHEATReload then
		if self.HEATDualReloadableIfNotEmpty then
			if not self.HEATEmptyReload then
				self.DualReloadable = true;
			else
				self.DualReloadable = false;
			end
		end
		if self:IsReloading() or (self.HEATParent and (self.HEATNonReloadStaging and self.Reloadable)) and not self:DoneReloading() then
			if self.HEATNonReloadStaging then
				-- Only deactivate here, because we still want vanilla EmptyClicks to be able to play
				self:Deactivate();
				if self:IsReloading() then
					self.HEATNonReloadStaging = false;
				end
			end
			
			local screen;
			if self.HEATParent then
				screen = ActivityMan:GetActivity():ScreenOfPlayer(self.HEATParentController.Player);
			end

			self.HEATFireDelayTimer:Reset()
			self.HEATDelayedFireActivated = false;
			self.HEATDelayedFire = false;
			
			if not self.HEATCurrentReloadPhaseData then
				self.HEATCurrentReloadPhaseData = {};
				-- To support things in callbacks overriding values without overriding originals, we need a table copy:
				for k, v in pairs(self.HEATReloadPhases[self.HEATCurrentReloadPhase]) do
					self.HEATCurrentReloadPhaseData[k] = v;
				end
				if self.HEATVerboseLogging then
					print("HEATSystem: Gun " .. self.PresetName .. " entered reload phase " .. self.HEATCurrentReloadPhase .. " named " .. self.HEATCurrentReloadPhaseData.Name);
				end
				-- Clear interruption status if we've just began a loop, to avoid it leaking from any previous phases
				if self.HEATCurrentReloadPhaseData.shotgunReloadLoop then
					self.HEATManualInterruptionAttempted = false;
				end				
			end
			
			if self.HEATWasInterrupted then
				self.HEATWasInterrupted = false;
				-- Autocalculate best guesses again so we can keep it accurate
				local totalTime = 50;
				if self.HEATEmptyReload and not self.HEATTotalEmptyReloadTimeOverride then
					for i = self.HEATCurrentReloadPhase, #self.HEATReloadPhases do
						totalTime = totalTime + self.HEATReloadPhases[i].prepareDelay + self.HEATReloadPhases[i].afterDelay;
					end	
					self.BaseReloadTime = totalTime;
				elseif not self.HEATTotalFullReloadTimeOverride then
					for i = self.HEATCurrentReloadPhase, #self.HEATReloadPhases do
						totalTime = totalTime + self.HEATReloadPhases[i].prepareDelay + self.HEATReloadPhases[i].afterDelay;
						if self.HEATReloadPhases[i].endIfNotEmptyReload then
							break;
						end
					end
					self.BaseReloadTime = totalTime;
				end
			end
					
			if not self.HEATReloadPhaseOnInterrupt then
				self.HEATReloadPhaseOnInterrupt = self.HEATCurrentReloadPhaseData.phaseOnInterrupt or nil;
			end
			
			if self.HEATReloadTimer:IsPastSimMS(self.HEATCurrentReloadPhaseData.prepareDelay - self.HEATCurrentReloadPhaseData.prepareSoundLength) and self.HEATPrepareSoundPlayed ~= true then
				self.HEATPrepareSoundPlayed = true;
				if self.HEATCurrentReloadPhaseData.prepareSound then
					self.HEATCurrentReloadPhaseData.prepareSound:Play(self.Pos)
				end
			end
			
			self.Frame = self.HEATCurrentReloadPhaseData.autoAnimateFrames and self.HEATCurrentReloadPhaseData.startFrame or self.Frame;
			self.HEATRotationTarget = self.HEATCurrentReloadPhaseData.rotationTarget;
			
			self.HEATReloadStanceOffsetTarget = self.HEATCurrentReloadPhaseData.reloadStanceOffsetTarget;
			self.HEATReloadSupportOffsetSpeed = self.HEATCurrentReloadPhaseData.reloadSupportOffsetSpeed;
			self.HEATReloadSupportOffsetTarget = self.HEATCurrentReloadPhaseData.reloadSupportOffsetTarget;
			
			if self.HEATEnterPhaseCallbackDone ~= true then
				self.HEATEnterPhaseCallbackDone = true;
				self.HEATCurrentReloadPhaseData.enterPhaseCallback(self);
			end
			
			self.HEATCurrentReloadPhaseData.constantCallback(self);
		
			if self.HEATReloadTimer:IsPastSimMS(self.HEATCurrentReloadPhaseData.prepareDelay) then
			
				-- Frame animation
				if self.HEATCurrentReloadPhaseData.autoAnimateFrames then
					local progressFactor = (self.HEATReloadTimer.ElapsedSimTimeMS - self.HEATCurrentReloadPhaseData.prepareDelay) / self.HEATCurrentReloadPhaseData.afterDelay
					progressFactor = self.HEATCurrentReloadPhaseData.easingFunction(progressFactor);
					if progressFactor > 1 then
						progressFactor = 1;
					end			
				
					local frameChange = self.HEATCurrentReloadPhaseData.endFrame - self.HEATCurrentReloadPhaseData.startFrame
					self.Frame = math.floor(self.HEATCurrentReloadPhaseData.startFrame + math.floor(frameChange * progressFactor + 0.55))
				end
				
				if self.HEATParent and self.HEATParent:IsPlayerControlled() then
					if self.HEATParentController:IsState(Controller.WEAPON_FIRE) then
						self.HEATManualInterruptionAttempted = true;
						if self.HEATCurrentReloadPhaseData.shotgunReloadLoop then
							PrimitiveMan:DrawTextPrimitive(screen, self.HEATParent.AboveHUDPos + Vector(0, 30), "Interrupting...", true, 1);
						end
					end
				end
				
				if self.HEATPhaseFinishDone ~= true then
				
					if self.HEATCurrentReloadPhaseData.removesMag and not self:NumberValueExists("HEAT_FakeMagRemoved") then
						self:SetNumberValue("HEAT_FakeMagRemoved", 1);
						local fakeMag
						fakeMag = self.HEATFakeMagazineMOSRotating:Clone();
						fakeMag.Pos = self.Pos + Vector(self.HEATFakeMagazineOffset.X * self.FlipFactor, self.HEATFakeMagazineOffset.Y):RadRotate(self.RotAngle);
						fakeMag.Vel = self.Vel + Vector(self.HEATFakeMagazineVelocity.X * self.FlipFactor, self.HEATFakeMagazineVelocity.Y):RadRotate(self.RotAngle);
						fakeMag.RotAngle = self.RotAngle;
						fakeMag.AngularVel = self.HEATFakeMagazineAngularVel * self.FlipFactor;
						fakeMag.HFlipped = self.HFlipped;
						MovableMan:AddParticle(fakeMag);
					elseif self.HEATCurrentReloadPhaseData.addsMag then
						self:RemoveNumberValue("HEAT_FakeMagRemoved");
					end				
				
					self.HEATAngVel = self.HEATAngVel + self.HEATCurrentReloadPhaseData.angVel;
					self.HEATHorizontalAnim = self.HEATHorizontalAnim + self.HEATCurrentReloadPhaseData.horizontalAnim;
					self.HEATVerticalAnim = self.HEATVerticalAnim + self.HEATCurrentReloadPhaseData.verticalAnim;
					
					if self.HEATCurrentReloadPhaseData.shotgunReloadLoop then
						self.HEATAmmoCounter = self.HEATAmmoCounter + 1;
						self.HEATApplyAmmoCount = true;		
					end
					
					if not self.HEATReloadPhaseOnInterrupt then
						if self.HEATCurrentReloadPhaseData.autoProgressIfFinishedButInterrupted and not ((not self.HEATEmptyReload) and self.HEATCurrentReloadPhaseData.endIfNotEmptyReload) then
						if self.HEATVerboseLogging then
							print("HEATSystem: Gun " .. self.PresetName .. " autoprogressed from phase " .. self.HEATCurrentReloadPhase);
						end
							if type(self.HEATCurrentReloadPhaseData.autoProgressIfFinishedButInterrupted) == "number" then
								self.HEATReloadPhaseOnInterrupt = self.HEATCurrentReloadPhaseData.autoProgressIfFinishedButInterrupted;
							else
								self.HEATReloadPhaseOnInterrupt = self.HEATCurrentReloadPhase + 1;
							end
						end
					end
					
					-- If this is an autoprogress-if-finished phase the user probably wants the persistent frame set early here instead of at exit
					if self.HEATCurrentReloadPhaseData.autoProgressIfFinishedButInterrupted then
						self.HEATPersistentFrame = self.HEATCurrentReloadPhaseData.setEndFrameAsPersistent and self.HEATCurrentReloadPhaseData.endFrame or self.HEATPersistentFrame;
					end

					if self.HEATCurrentReloadPhaseData.afterSound then
						self.HEATCurrentReloadPhaseData.afterSound:Play(self.Pos);
						self.HEATCurrentReloadPhaseData.finishCallback(self);
					end
					
					if self.HEATToSpawnCasing and self.HEATCurrentReloadPhaseData.spawnCasing then
						local casing
						casing = self.HEATCasing:Clone();
						if not self.HEATCasingOffset then
							casing.Pos = self.EjectionPos;
						else
							casing.Pos = self.Pos + Vector(self.HEATCasingOffset.X * self.FlipFactor, self.HEATCasingOffset.Y):RadRotate(self.RotAngle);
						end
						casing.Vel = self.Vel + Vector(self.HEATCasingVelocity.X * self.FlipFactor, self.HEATCasingVelocity.Y):RadRotate(self.RotAngle);
						casing.RotAngle = self.RotAngle;
						casing.HFlipped = self.HFlipped;
						MovableMan:AddParticle(casing);
						if self.HEATVerboseLogging then
							print("HEATSystem: Gun " .. self.PresetName .. " spawned casing " .. casing.PresetName);
						end
						self.HEATToSpawnCasing = false;
					end
					
					self.HEATPhaseFinishDone = true;
					
				end
				
				if self.HEATReloadTimer:IsPastSimMS(self.HEATCurrentReloadPhaseData.prepareDelay + self.HEATCurrentReloadPhaseData.afterDelay) then
					self.HEATReloadTimer:Reset();
					self.HEATPrepareSoundPlayed = false;
					self.HEATPhaseFinishDone = false;
					
					self.HEATEnterPhaseCallbackDone = false;
					
					if self.HEATForceEndReload then
						self.HEATEndReload(self);		
					elseif self.HEATReloadPhaseOverride then
						self.HEATCurrentReloadPhase = self.HEATReloadPhaseOverride;
					elseif self.HEATCurrentReloadPhaseData.shotgunReloadLoop and self.HEATAmmoCounter < ((self.HEATEmptyReload and self.HEATPlusOneChamberedRound) and (self.HEATFullMagazineRoundCount - 1) or self.HEATFullMagazineRoundCount) then
						if self.HEATManualInterruptionAttempted then
							-- If we're in a loop and there appears to be no next phase, then just end the reload
							if self.HEATReloadPhases[self.HEATCurrentReloadPhase + 1] == nil then
								self.HEATEndReload(self);	
							else
								self.HEATCurrentReloadPhase = self.HEATCurrentReloadPhase + 1;
							end	
						else
							-- Repeat
						end
					elseif (not self.HEATEmptyReload) and self.HEATCurrentReloadPhaseData.endIfNotEmptyReload then
						self.HEATEndReload(self);
					elseif (self.HEATCurrentReloadPhaseData.shotgunReloadLoop) then
						local ammoCountToCheckFor = (self.HEATEmptyReload and self.HEATPlusOneChamberedRound) and (self.HEATFullMagazineRoundCount - 1) or self.HEATFullMagazineRoundCount;
						if (self.HEATAmmoCounter >= ammoCountToCheckFor) then
							-- If we're in a loop and there appears to be no next phase, then just end the reload
							if self.HEATReloadPhases[self.HEATCurrentReloadPhase + 1] == nil then
								self.HEATEndReload(self);	
							else
								self.HEATCurrentReloadPhase = self.HEATCurrentReloadPhase + 1;
							end
						end
					elseif self.HEATReloadPhases[self.HEATCurrentReloadPhase + 1] == nil then
						self.HEATEndReload(self);
					else
						self.HEATCurrentReloadPhase = self.HEATCurrentReloadPhase + 1;
					end

					-- Set a persistent frame if applicable
					self.HEATPersistentFrame = self.HEATCurrentReloadPhaseData.setEndFrameAsPersistent and self.HEATCurrentReloadPhaseData.endFrame or self.HEATPersistentFrame;
					
					self.HEATCurrentReloadPhaseData.exitPhaseCallback(self);
					self.HEATReloadPhaseOnInterrupt = nil;
					self.HEATReloadPhaseOverride = nil;
					self.HEATForceEndReload = false;
					self.HEATCurrentReloadPhaseData = nil;			
				end
			end
		else
			if self.BaseReloadTime == 0 then
				self.BaseReloadTime = self.HEATTotalFullReloadTime;
			end
		
			self.HEATCurrentReloadPhaseData = nil;
			self.HEATPrepareSoundPlayed = false;
			self.HEATPhaseFinishDone = false;
			
			self.HEATReloadTimer:Reset();
			if self.HEATReloadPhaseOnInterrupt then
				self.HEATCurrentReloadPhase = self.HEATReloadPhaseOnInterrupt;
				self.HEATReloadPhaseOnInterrupt = nil;
				self.HEATWasInterrupted = true;
			end
		
			self.HEATCurrentReloadPhaseData = nil;
			self.HEATPrepareSoundPlayed = false;
			self.HEATPhaseFinishDone = false;
			
		end
	
		if self:DoneReloading() == true then
			self.HEATRecoilAIHomingFactor = 0;
			self.HEATFireDelayTimer:Reset()
			if self.HEATApplyAmmoCount then
				self.Magazine.RoundCount = self.HEATAmmoCounter;
			else
				self.Magazine.RoundCount = self.HEATFullMagazineRoundCount;
				if self.HEATEmptyReload and self.HEATPlusOneChamberedRound then
					self.Magazine.RoundCount = math.max(1, self.Magazine.RoundCount - 1);
				end
			end
			self.HEATEmptyReload = false;
			
			self.HEATDoneReloadingCallback(self);
			
		end	
	end

	-- Delayed fire system
	
	if self.useHEATDelayedFire then
		local fire = self:IsActivated() and self.RoundInMagCount > 0;

		if self.HEATParent and self.HEATDelayedFirstShot == true then
			if self.RoundInMagCount > 0 then
				self:Deactivate()
			end
			--if self.parent:GetController():IsState(Controller.WEAPON_FIRE) and not self:IsReloading() then
			if fire and not self:IsReloading() then
				if not self.Magazine or self.Magazine.RoundCount < 1 then
					--self:Reload()
					self:Activate()
				elseif not self.HEATDelayedFireActivated and not self.HEATDelayedFire and self.HEATFireDelayTimer:IsPastSimMS(1 / (self.RateOfFire / 60) * 1000) then
					self.HEATDelayedFireActivated = true
					
					if self.HEATPreSound then
						self.HEATPreSound:Play(self.Pos);
					end
					
					self.HEATFireDelayTimer:Reset()
					
					self.HEATDelayedFire = true
					self.HEATDelayedFireTimer:Reset()
				end
			else
				if self.HEATDelayedFireActivated then
					self.HEATDelayedFireActivated = false
				end
			end
		elseif fire == false then
			self.HEATDelayedFirstShot = true;
		end
	end
	
	if self.FiredFrame then
	
		self.HEATAmmoCounter = self.HEATAmmoCounter - 1;
		self.HEATToSpawnCasing = true;
	
		self.HEATHorizontalAnim = self.HEATRecoilHorizontalAnim;
		self.HEATFiringAnimationTimer:Reset();
	
		local actingRecoilAngAnim;
	
		if self.HEATParent and not self.HEATParent:IsPlayerControlled() then
			self.HEATRecoilAIHomingFactor = math.min(1, self.HEATRecoilAIHomingFactor + 1 / math.ceil((self.HEATFullMagazineRoundCount)));
			actingRecoilAngAnim = 0;
		else
			actingRecoilAngAnim = self.HEATRecoilAngAnim;
		end
	
		self.HEATAngVel = self.HEATAngVel - RangeRand(1 - self.HEATRecoilAngVariation / 2, 1 + self.HEATRecoilAngVariation / 2) * actingRecoilAngAnim
		
		if self.HEATStageAfterEveryShot then
			self.HEATNonReloadStaging = true;
			self.HEATCurrentReloadPhase = self.HEATPhaseAfterFiringIfNotReloading or 1;
		end
		
		if self.RoundInMagCount > 0 then
		else
			self.HEATEmptyReload = true;
			self.BaseReloadTime = self.HEATTotalEmptyReloadTime;
		end
		
		if self.useHEATCompliSound then
			local outdoorRays = 0;
			local indoorRays = 0;
			local bigIndoorRays = 0;
			local rayThreshold = 2;

			if self.HEATParent and self.HEATParent:IsPlayerControlled() then
				local Vector2 = Vector(0,-700); -- straight up
				local Vector2Left = Vector(0,-700):RadRotate(45*(math.pi/180));
				local Vector2Right = Vector(0,-700):RadRotate(-45*(math.pi/180));			
				local Vector2SlightLeft = Vector(0,-700):RadRotate(22.5*(math.pi/180));
				local Vector2SlightRight = Vector(0,-700):RadRotate(-22.5*(math.pi/180));		
				local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
				local Vector4 = Vector(0,0); -- dont need this but is needed as an arg

				self.ray = SceneMan:CastObstacleRay(self.Pos, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
				self.rayRight = SceneMan:CastObstacleRay(self.Pos, Vector2Right, Vector3, Vector4, self.RootID, self.Team, 128, 7);
				self.rayLeft = SceneMan:CastObstacleRay(self.Pos, Vector2Left, Vector3, Vector4, self.RootID, self.Team, 128, 7);			
				self.raySlightRight = SceneMan:CastObstacleRay(self.Pos, Vector2SlightRight, Vector3, Vector4, self.RootID, self.Team, 128, 7);
				self.raySlightLeft = SceneMan:CastObstacleRay(self.Pos, Vector2SlightLeft, Vector3, Vector4, self.RootID, self.Team, 128, 7);
				
				self.rayTable = {self.ray, self.rayRight, self.rayLeft, self.raySlightRight, self.raySlightLeft};
			else
				rayThreshold = 1; -- has to be different for AI
				local Vector2 = Vector(0,-700); -- straight up
				local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
				local Vector4 = Vector(0,0); -- dont need this but is needed as an arg		
				self.ray = SceneMan:CastObstacleRay(self.Pos, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
				
				self.rayTable = {self.ray};
			end
			
			for _, rayLength in ipairs(self.rayTable) do
				if rayLength < 0 then
					outdoorRays = outdoorRays + 1;
				elseif rayLength > 170 then
					bigIndoorRays = bigIndoorRays + 1;
				else
					indoorRays = indoorRays + 1;
				end
			end
			
			if outdoorRays >= rayThreshold then
				if self.HEATReflectionOutdoorsSound then
					self.HEATReflectionOutdoorsSound:Play(self.Pos);
				end
			else
				if self.HEATReflectionIndoorsSound then
					self.HEATReflectionIndoorsSound:Play(self.Pos);
				end
			end
		end
		
		-- Smoke
		if self.useHEATParticleUtilityFiringSmoke then
			self.HEATParticleUtilityFiringSmokeDataTable.Position = self.MuzzlePos;
			self.HEATParticleUtilityFiringSmokeDataTable.Source = self;
			self.HEATParticleUtilityFiringSmokeDataTable.RadAngle = self.HFlipped and (self.RotAngle + math.pi) or self.RotAngle;
			self.HEATParticleUtility:CreateDirectionalSmokeEffect(self.HEATParticleUtilityFiringSmokeDataTable);
		end
		
		self.HEATFireCallback(self);
	end
	
	if self.HEATParent and self.HEATParent:IsPlayerControlled() then
		self.HEATRecoilAIHomingFactor = 0;
	elseif not self:IsActivated() then
		self.HEATRecoilAIHomingFactor = math.max(0, self.HEATRecoilAIHomingFactor - TimerMan.DeltaTimeSecs / 50);
	end
	
	if self.HEATDelayedFire and self.HEATDelayedFireTimer:IsPastSimMS(self.HEATDelayedFireTimeMS) then
		self:Activate()
		-- Super roundabout dual wielding fire fix - it won't choose the other weapon to fire if it "fires itself"
		if self.HEATParent then
			self.HEATParentController:SetState(Controller.WEAPON_FIRE, true);
		end
		self.HEATDelayedFire = false
		self.HEATDelayedFirstShot = false;
	end
	
	-- Animation
	if self.HEATParent then
		self.HEATHorizontalAnim = math.floor(self.HEATHorizontalAnim / (1 + TimerMan.DeltaTimeSecs * 24.0) * 1000) / 1000
		self.HEATVerticalAnim = math.floor(self.HEATVerticalAnim / (1 + TimerMan.DeltaTimeSecs * 15.0) * 1000) / 1000
		
		local stance = Vector()
		stance = stance + Vector(-1,0) * self.HEATHorizontalAnim -- Horizontal animation
		stance = stance + Vector(0,5) * self.HEATVerticalAnim -- Vertical animation
		
		self.HEATRotationTarget = self.HEATRotationTargetOverride or self.HEATRotationTarget;
		self.HEATRotationTarget = self.HEATRotationTarget - (self.HEATAngVel * 4) + self.HEATRotationTargetManualAddition;
		
		if self.useHEATRecoil then				
			local crouching = self.HEATParentController:IsState(Controller.BODY_WALKCROUCH)
			local proning = self.HEATParentController:IsState(Controller.BODY_PRONE)
			
			local actingRecoilStrength;
			if proning then
				actingRecoilStrength = self.HEATRecoilStrength * self.HEATRecoilProneMultiplier;
			elseif crouching then
				actingRecoilStrength = self.HEATRecoilStrength * self.HEATRecoilCrouchMultiplier;
			else
				actingRecoilStrength = self.HEATRecoilStrength;
			end
		
			if self.FiredFrame then
				self.HEATRecoilStr = self.HEATRecoilStr + ((math.random(10, self.HEATRecoilRandomUpper * 10) / 10) * 0.5 * actingRecoilStrength) + (self.HEATRecoilStr * 0.6 * self.HEATRecoilPowStrength)
			end
			
			self.HEATRecoilStr = math.floor(self.HEATRecoilStr / (1 + TimerMan.DeltaTimeSecs * 8.0 * self.HEATRecoilDamping) * 1000) / 1000
			self.HEATRecoilAcc = (self.HEATRecoilAcc + self.HEATRecoilStr * TimerMan.DeltaTimeSecs) % (math.pi * 4)
			
			local recoilA = (math.sin(self.HEATRecoilAcc) * self.HEATRecoilStr) * 0.05 * self.HEATRecoilStr
			local recoilB = (math.sin(self.HEATRecoilAcc * 0.5) * self.HEATRecoilStr) * 0.01 * self.HEATRecoilStr
			local recoilC = (math.sin(self.HEATRecoilAcc * 0.25) * self.HEATRecoilStr) * 0.05 * self.HEATRecoilStr
			
			local recoilFinal = math.max(math.min(recoilA + recoilB + recoilC, self.HEATRecoilMax), -self.HEATRecoilMax/10)
			
			self.SharpLength = math.max(self.HEATOriginalSharpLength * self.HEATSharpLengthMinimumMult, math.max(self.HEATOriginalSharpLength - (self.HEATRecoilStr * 3 + math.abs(recoilFinal)), 0))
			
			local AIHomingFactorRecoilShift = self.HEATRecoilAIHomingFactor * (-recoilFinal);
			
			--print(AIHomingFactorRecoilShift)
			self.HEATRotationTarget = self.HEATRotationTarget + recoilFinal + AIHomingFactorRecoilShift -- apply the recoil
		end
		
		self.HEATRotation = (self.HEATRotation + self.HEATRotationTarget * TimerMan.DeltaTimeSecs * self.HEATRotationSpeed) / (1 + TimerMan.DeltaTimeSecs * self.HEATRotationSpeed)
		if self:IsReloading() or self.HEATNonReloadStaging then
			self.SupportOffset = self.SupportOffset + ((self.HEATReloadSupportOffsetTarget - self.SupportOffset) * TimerMan.DeltaTimeSecs * self.HEATReloadSupportOffsetSpeed)
		else
			self.SupportOffset = self.HEATOriginalSupportOffset;
		end
		local total = math.rad(self.HEATRotation) * self.FlipFactor
		
		self.InheritedRotAngleOffset = total * self.FlipFactor;
		self:SetNumberValue("HEAT_CurrentRecoil", total);
		-- self.RotAngle = self.RotAngle + total;
		-- self:SetNumberValue("MagRotation", total);
		
		-- local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		-- local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		-- self.Pos = self.Pos + offsetTotal;
		-- self:SetNumberValue("MagOffsetX", offsetTotal.X);
		-- self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		if self.HEATReloadStanceOffsetTarget then
			self.HEATReloadStanceOffset = self.HEATReloadStanceOffset + ((self.HEATReloadStanceOffsetTarget - self.HEATReloadStanceOffset) * TimerMan.DeltaTimeSecs * 2.5)
			self.StanceOffset = Vector(self.HEATOriginalStanceOffset.X, self.HEATOriginalStanceOffset.Y) + stance + self.HEATReloadStanceOffset
			self.SharpStanceOffset = Vector(self.HEATOriginalSharpStanceOffset.X, self.HEATOriginalSharpStanceOffset.Y) + stance + self.HEATReloadStanceOffset;
		else
			self.HEATReloadStanceOffset = Vector(0, 0)
			self.StanceOffset = Vector(self.HEATOriginalStanceOffset.X, self.HEATOriginalStanceOffset.Y) + stance
			self.SharpStanceOffset = Vector(self.HEATOriginalSharpStanceOffset.X, self.HEATOriginalSharpStanceOffset.Y) + stance
		end
	end
end

function OnSave(self)
	self:SaveNumberValue("heatAmmoCounter", self.HEATAmmoCounter);
end