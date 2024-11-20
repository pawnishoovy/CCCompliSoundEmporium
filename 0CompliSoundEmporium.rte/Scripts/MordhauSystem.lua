require("MasterTerrainIDList")

function OnMessage(self, message, object)
	if message == "Mordhau_ReceiveBlockableAttack" then
		if self.CurrentPhaseData then
			if self.CurrentPhaseData.blocksAttacks then
				MovableMan:FindObjectByUniqueID(object.senderUniqueID):SendMessage("Mordhau_MessageReturn_BlockResponse", "Blocked");
				self.BlockFunction(self, object.attackType, object.hitPos);
			elseif self.CurrentPhaseData.parriesAttacks then
				MovableMan:FindObjectByUniqueID(object.senderUniqueID):SendMessage("Mordhau_MessageReturn_BlockResponse", "Parried");
				self.BlockFunction(self, object.attackType, object.hitPos);
				self.CurrentPhaseData.allowsPhaseSetBuffering = true;
				self.CurrentPhaseData.canComboOut = true;
			end
		end
	elseif message == "Mordhau_MessageReturn_BlockResponse" then
		self.MessageReturn_BlockResponse = object;
		self.BeingBlockedFunction(self);
	elseif message == "Mordhau_HitFlinch" then
		if self.PlayingPhaseSet then
			if not self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet then
				self.FlinchCooldownTimer:Reset();
				self.PlayingPhaseSet = false;
			end
		end
	end
end

function playPhaseSet(self, name)
	if self.PhaseSetIndexForName[name] then
		self.CurrentPhaseSet = self.PhaseSetIndexForName[name];
		self.CurrentPhase = 1;
		self.CurrentPhaseData = nil;
		self.PlayingPhaseSet = true;
		self.PhaseTimer:Reset();
		
		self.MessageReturn_BlockResponse = false;
		self.PhaseSetWasBlocked = false;
		self.PhaseSetWasParried = false;
		self.PhaseSetWasInterruptedByTerrain = false;
		self.WeaponIDToIgnore = nil;
		self.HitMOTable = {};
	else
		print("ERROR: MordhauSystem could not find PhaseSet it was asked to play of name " .. name);
		return false;
	end
end

function getPhaseSetByName(self, name)
	if self.PhaseSetIndexForName[name] then
		return self.PhaseSets[self.PhaseSetIndexForName[name]];
	else
		return nil;
	end
end

function Create(self)	

	-----------------
	----------------- Sounds and FX
	-----------------
	
	-- Default HitMOFunction. Handles Slash/Stab, Metal/Flesh, among other things.
	if not self.HitMOFunction then
		self.HitMOFunction = function (self, hitTarget, hitPos)
			local hitType;		
			local woundName = hitTarget:GetEntryWoundPresetName();
			local material = hitTarget.Material.PresetName;
			
			if string.find(material,"Flesh") or string.find(woundName,"Flesh") or string.find(material,"Bone") or string.find(woundName,"Bone") then
				hitType = "Flesh";
			else
				hitType = "Metal";
			end
			
			if hitType == "Flesh" then
				local effect = self.HitGFX.Flesh:Clone();
				effect.Pos = self.LastHitTargetPosition;
				MovableMan:AddParticle(effect);
				effect:GibThis();			
			
				if self.CurrentPhaseData and self.CurrentPhaseData.attackType == "Stab" and self.HitSFX.StabFlesh then
					self.HitSFX.StabFlesh:Play(self.Pos);
				elseif self.HitSFX.SlashFlesh then
					self.HitSFX.SlashFlesh:Play(self.Pos);
				elseif self.HitSFX.Default then
					self.HitSFX.Default:Play(self.Pos);
				end
			else
				local effect = self.HitGFX.Metal:Clone();
				effect.Pos = self.LastHitTargetPosition;
				MovableMan:AddParticle(effect);
				effect:GibThis();			
						
			
				if self.CurrentPhaseData and self.CurrentPhaseData.attackType == "Stab" and self.HitSFX.StabMetal then
					self.HitSFX.StabMetal:Play(self.Pos);
				elseif self.HitSFX.SlashMetal then
					self.HitSFX.SlashMetal:Play(self.Pos);
				elseif self.HitSFX.Default then
					self.HitSFX.Default:Play(self.Pos);
				end
			end
		end
	end
	
	if not self.BeingBlockedFunction then
		self.BeingBlockedFunction = function (self)
			self.HitSFX.BeingBlocked:Play(self.Pos);
		end
	end
	
	if not self.BlockFunction then
		self.BlockFunction = function (self, attackType, hitPos)
			if string.find(attackType, "Stab") then
				if self.BlockSFX.BlockStab then
					self.BlockSFX.BlockStab:Play(self.Pos);
				end
				if self.BlockGFX.BlockStab then
					local effect = self.BlockGFX.BlockStab:Clone();
					effect.Pos = hitPos;
					MovableMan:AddParticle(effect);
					effect:GibThis();
				end
			else
				if self.BlockSFX.BlockSlash then
					self.BlockSFX.BlockSlash:Play(self.Pos);
				end
				if self.BlockGFX.BlockSlash then
					local effect = self.BlockGFX.BlockSlash:Clone();
					effect.Pos = hitPos;
					MovableMan:AddParticle(effect);
					effect:GibThis();
				end
			end
			
			if string.find(attackType, "Heavy") then
				if self.BlockSFX.HeavyBlock then
					self.BlockSFX.HeavyBlock:Play(self.Pos);
				end
				if self.BlockGFX.HeavyBlockAdd then
					local effect = self.BlockGFX.HeavyBlockAdd:Clone();
					effect.Pos = hitPos;
					MovableMan:AddParticle(effect);
					effect:GibThis();
				end
			end
			
			if self.CurrentPhaseData and self.CurrentPhaseData.parriesAttacks then
				if self.BlockGFX.Parry then
					local effect = self.BlockGFX.Parry:Clone();
					effect.Pos = hitPos;
					MovableMan:AddParticle(effect);
					effect:GibThis();
				end
				if self.BlockSFX.ParryAdd then
					self.BlockSFX.ParryAdd:Play(self.Pos);
				end
			end
		end
	end
	
	-----------------
	----------------- Melee
	-----------------
	
	self.FlinchCooldownTimer = Timer();
	
	self.ParryCooldownTimer = Timer();

	-----------------
	----------------- PhaseSet
	-----------------	
	
	-- Find the indexes of all our PhaseSets so we can play them by name easily later.
	self.PhaseSetIndexForName = {};
	for k, v in ipairs(self.PhaseSets) do
		self.PhaseSetIndexForName[v.Name] = k;
	end
	
	self.PhaseTimer = Timer();
	self.CurrentPhaseSet = 1;
	self.CurrentPhase = 1;
	
	self.BufferedPhaseSet = nil;
	
	-----------------
	----------------- Animation
	-----------------

	self.OriginalJointOffset = Vector(math.abs(self.JointOffset.X), self.JointOffset.Y);
	self.OriginalSupportOffset = Vector(math.abs(self.SupportOffset.X), self.SupportOffset.Y);
	self.OriginalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	
	self.RotationSpeed = self.IdleRotationSpeed;
	self.RotationTarget = 0;
	self.Rotation = 0;
	self.RotationTargetManualAddition = 0;
	
	self.JointOffsetSpeed = 15;
	self.JointOffsetTarget = self.OriginalJointOffset;
	
	self.SupportOffsetSpeed = 15;
	self.SupportOffsetTarget = self.OriginalSupportOffset;
	
	self.MordhauStanceOffset = Vector(0, 0);
	self.StanceOffsetSpeed = 15;
	self.StanceOffsetTarget = self.OriginalStanceOffset;
	
end

function OnAttach(self, newParent)
	if IsAHuman(newParent:GetRootParent()) then
		self.Parent = ToAHuman(newParent:GetRootParent());
		self.ParentController = self.Parent:GetController();
	end
end

function OnDetach(self)
	self.Parent = nil;
	self.ParentController = nil;
end

function ThreadedUpdate(self)
	self.AngVel = 0;
	self.HorizontalAnim = 0;
	self.VerticalAnim = 0;

	if self.Parent then
		local isPlayerControlled = self.Parent:IsPlayerControlled();

		local primaryInput = self:IsActivated();
		local primaryHotkeyInput = self:HotkeyActionIsActivated(HeldDevice.PRIMARYHOTKEY);
		local auxiliaryHotkeyInput = self:HotkeyActionIsActivated(HeldDevice.AUXILIARYHOTKEY);
		-- TODO: real input handling for the reload block crap
		local anyAttackInput = primaryInput or primaryHotkeyInput or auxiliaryHotkeyInput;
		local reloadInput = self.ParentController:IsState(Controller.WEAPON_RELOAD) 
		local heldReloadInput = isPlayerControlled and self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet and UInputMan:KeyHeld(Key.R);
		
		-- TODO: real AI
		if primaryInput and not isPlayerControlled then
			if math.random(0, 100) > 50 then
				primaryHotkeyInput = true;
				primaryInput = false;
			end
		end
	
		-- Phase handling
		if self.PlayingPhaseSet then
			-- Copy phase data to work with
			if not self.CurrentPhaseData then
				self.CurrentPhaseEndSoundPlayed = false;
				self.CurrentPhaseStartSoundPlayed = false;
				self.PhaseTimer:Reset();		
				self.CurrentPhaseData = {};
				-- To support things in callbacks overriding values without overriding originals, we need a table copy:
				for k, v in pairs(self.PhaseSets[self.CurrentPhaseSet].Phases[self.CurrentPhase]) do
					self.CurrentPhaseData[k] = v;
				end
				if self.DebugInfo then
					print("MordhauSystem: Weapon " .. self.PresetName .. " entered melee phase " .. self.CurrentPhase .. " named " .. self.CurrentPhaseData.Name .. " from phase set " .. self.PhaseSets[self.CurrentPhaseSet].Name);
				end		
				if self.PhaseSetWasInterruptedByTerrain then
					if self.CurrentPhaseData.Cleaves then
						self.PhaseSetWasInterruptedByTerrain = false;
					else
						self.CurrentPhaseData.doesDamage = false;
					end
				end				
				if self.PhaseSetWasBlocked or self.PhaseSetWasInterruptedByTerrain then
					self.CurrentPhaseData.canBeBlockCancelled = true;
				end
			end
			
			if self.CurrentPhaseData.soundStart and not self.CurrentPhaseStartSoundPlayed then
				self.CurrentPhaseData.soundStart:Play(self.Pos);
				self.CurrentPhaseStartSoundPlayed = true;
			end
			
			-- If this is the block PhaseSet, allow reload input to hold it
			local blockHoldOverride = false;
			if self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet then
				blockHoldOverride = heldReloadInput;
			end

			-- Animation value setting
			
			local progressFactor = math.min(1, self.PhaseTimer.ElapsedSimTimeMS / self.CurrentPhaseData.Duration);
			local frameProgressFactor = self.CurrentPhaseData.frameEasingFunc(progressFactor);
			local angleProgressFactor = self.CurrentPhaseData.angleEasingFunc(progressFactor);
			local stanceProgressFactor = self.CurrentPhaseData.stanceEasingFunc(progressFactor);
	
			-- Frame anim, hard-set
			local frameChange = self.CurrentPhaseData.frameEnd - self.CurrentPhaseData.frameStart;
			self.Frame = math.floor(self.CurrentPhaseData.frameStart + math.floor(frameChange * frameProgressFactor + 0.55));
			
			-- Angle anim - requested, not hard-set
			self.RotationSpeed = self.CurrentPhaseData.rotationSpeed * 60;
			local angleChange = self.CurrentPhaseData.angleEnd - self.CurrentPhaseData.angleStart;
			self.RotationTarget = self.CurrentPhaseData.angleStart + (angleChange * angleProgressFactor);
			
			-- Hand offsets - requested, not hard-set
			self.JointOffsetSpeed = self.CurrentPhaseData.jointOffsetSpeed * 60;
			self.JointOffsetTarget = self.CurrentPhaseData.jointOffset;
			self.SupportOffsetSpeed = self.CurrentPhaseData.supportOffsetSpeed * 60;
			self.SupportOffsetTarget = self.CurrentPhaseData.supportOffset;
			
			-- Stance anim - requested, not hard-set
			self.StanceOffsetSpeed = self.CurrentPhaseData.stanceOffsetSpeed * 60;
			local stanceChange = self.CurrentPhaseData.stanceOffsetEnd - self.CurrentPhaseData.stanceOffsetStart;
			self.StanceOffsetTarget = self.CurrentPhaseData.stanceOffsetStart + (stanceChange * stanceProgressFactor);
	
			-- Do callback after we've set everything, so it can be overriden
			if self.EnterPhaseCallbackDone ~= true then
				self.EnterPhaseCallbackDone = true;
				self.CurrentPhaseData.enterPhaseCallback(self);
			end
			
			-- Buffer logic
			if self.CurrentPhaseData.allowsPhaseSetBuffering or self.CurrentPhaseData.canComboOut and not self.PhaseSetWasParried then
				if primaryInput then
					self.BufferedPhaseSet = self.PrimaryInputPhaseSetName;
				end
				if primaryHotkeyInput then
					self.BufferedPhaseSet = self.PrimaryHotkeyInputPhaseSetName;
				end
				if auxiliaryHotkeyInput then
					self.BufferedPhaseSet = self.AuxiliaryHotkeyInputPhaseSetName;
				end
			else
				self.BufferedPhaseSet = false;
			end
				
			-- Collision logic
			local foundValidMO;
			if self.CurrentPhaseData.canBeBlocked or self.CurrentPhaseData.doesDamage and not self.PhaseSetWasBlocked then		
				local vecBetweenRays = (self.CurrentPhaseData.rayVecSecondPos - self.CurrentPhaseData.rayVecFirstPos) / self.CurrentPhaseData.rayDensity;
				local rayPos = self.CurrentPhaseData.rayVecFirstPos;
				
				for i = 1, self.CurrentPhaseData.rayDensity do
					local rayVec = Vector(self.CurrentPhaseData.rayRange * self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(self.CurrentPhaseData.rayAngle*self.FlipFactor)
					local rayOrigin = Vector(self.Pos.X, self.Pos.Y) + Vector(rayPos.X * self.FlipFactor, rayPos.Y):RadRotate(self.RotAngle)
			
					if self.DebugInfo then
						PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVec,  5);
					end
				
					local moCheck = SceneMan:CastMORay(rayOrigin, rayVec, self.WeaponIDToIgnore or self.RootID, self.Team, 0, false, 1); -- Raycast
					if moCheck ~= rte.NoMOID then
						local mo = MovableMan:GetMOFromID(moCheck);
						self.LastHitTargetUniqueID = mo.UniqueID;
						self.LastHitTargetPosition = SceneMan:GetLastRayHitPos();
						
						self:RequestSyncedUpdate();
					elseif not self.PhaseSetWasInterruptedByTerrain then -- After checking for MOs, check for terrain
						local terrCheck = SceneMan:CastMaxStrengthRay(rayOrigin, rayOrigin + (rayVec * self.CurrentPhaseData.rayTerrainRangeMultiplier), 1);
						if terrCheck > 5 then
							self.LastHitTerrainPosition = SceneMan:GetLastRayHitPos();
							local terrainID = SceneMan:GetTerrMatter(self.LastHitTerrainPosition.X, self.LastHitTerrainPosition.Y);
							if terrainID ~= 0 then -- 0 = air		
								if self.CurrentPhaseData.isInterruptableByTerrain then
									if self.HitSFX[CompliSoundTerrainIDs[terrainID]] ~= nil then
										self.HitSFX[CompliSoundTerrainIDs[terrainID]]:Play(self.Pos);
									elseif self.HitSFX.Default then
										self.HitSFX.Default:Play(self.Pos);
									end
									if self.HitGFX[CompliSoundTerrainIDs[terrainID]] ~= nil then
										local effect = self.HitGFX[CompliSoundTerrainIDs[terrainID]]:Clone();
										effect.Pos = self.LastHitTerrainPosition;
										MovableMan:AddParticle(effect);
										effect:GibThis();
									elseif self.HitSFX.Default then
										local effect = self.HitGFX.Default:Clone();
										effect.Pos = self.LastHitTerrainPosition;
										MovableMan:AddParticle(effect);
										effect:GibThis();
									end											
								
									self.CurrentPhaseData.doesDamage = false;
									self.CurrentPhaseData.canBeBlockCancelled = true;
									
									self.PhaseSetWasInterruptedByTerrain = true;
									break;
								end
							end
						end
					end			
								
					rayPos = rayPos + vecBetweenRays;
				end
			end			
			
			-- Callback
			self.CurrentPhaseData.constantCallback(self);
		
			if self.PhaseSetWasParried then
				self.BufferedPhaseSet = "Parried Reaction PhaseSet";
				self.CurrentPhaseData.canComboOut = true;
				self.ParryCooldownTimer:Reset();
			end
			
			-- Apply buffer logic and end phase early if appropriate
			if self.CurrentPhaseData.canComboOut and self.BufferedPhaseSet then
				if getPhaseSetByName(self, self.BufferedPhaseSet) and getPhaseSetByName(self, self.BufferedPhaseSet).canBeCombodInto then
					local oldPhaseDurationLeft = self.CurrentPhaseData.Duration - self.PhaseTimer.ElapsedSimTimeMS;
					playPhaseSet(self, self.BufferedPhaseSet);
					self.CurrentPhaseData = nil;
					
					-- We played the buffered PhaseSet, so we can now copy in all its values
					-- and construct a pseudophase to replace the first phase
					local pseudoPhase = {};
					for k, v in pairs(self.PhaseSets[self.CurrentPhaseSet].Phases[self.CurrentPhase]) do
						pseudoPhase[k] = v;
					end

					pseudoPhase.Duration = pseudoPhase.Duration + math.max(0, (oldPhaseDurationLeft / 2));
					pseudoPhase.frameStart = self.Frame;
					pseudoPhase.angleStart = self.RotationTarget;
					pseudoPhase.stanceStart = self.StanceOffsetTarget;
					pseudoPhase.jointOffsetStart = self.JointOffsetTarget;
					pseudoPhase.SupportOffsetStart = self.supportOffsetTarget;
					
					self.CurrentPhaseData = pseudoPhase;

					self.CurrentPhaseEndSoundPlayed = false;
					self.CurrentPhaseStartSoundPlayed = false;
					self.PhaseTimer:Reset();
					
					if self.DebugInfo then
						print("MordhauSystem: Weapon " .. self.PresetName .. " entered buffered pseudo phase into new phase set " .. self.BufferedPhaseSet);
					end
				end
				
				self.BufferedPhaseSet = nil
			end

			-- End logic
			if self.PhaseTimer:IsPastSimMS(self.CurrentPhaseData.Duration) then	
				if self.CurrentPhaseData.soundEnd and not self.CurrentPhaseEndSoundPlayed then
					self.CurrentPhaseData.soundEnd:Play(self.Pos);
					self.CurrentPhaseEndSoundPlayed = true;
				end
				
				if not (self.CurrentPhaseData.canBeHeld and (anyAttackInput or blockHoldOverride)) then	
					if self.PhaseSets[self.CurrentPhaseSet].Phases[self.CurrentPhase + 1] then
						self.CurrentPhase = self.CurrentPhase + 1;
					else
						self.PlayingPhaseSet = false;
						self.CurrentPhase = 1;
					end
						
					self.CurrentPhaseData.exitPhaseCallback(self);
					self.CurrentPhaseData = nil;
					self.PhaseTimer:Reset()
				end
			else
				-- Block cancelling - this is instant, so we do it here so nothing complains about missing CurrentPhaseData
				if self.CurrentPhaseData.canBeBlockCancelled then
					if reloadInput then
						playPhaseSet(self, self.BlockInputPhaseSetName);
					end
				end
			end
		else
			self.RotationSpeed = self.IdleRotationSpeed * 60;
			self.RotationTarget = self.IdleRotation;
			self.JointOffsetTarget = self.OriginalJointOffset;
			self.SupportOffsetTarget = self.OriginalSupportOffset;
			self.StanceOffsetTarget = Vector(0, 0);
			
			if self.FlinchCooldownTimer:IsPastSimMS(self.FlinchCooldown) and self.ParryCooldownTimer:IsPastSimMS(self.ParryCooldown) then
				if primaryInput then
					playPhaseSet(self, self.PrimaryInputPhaseSetName);
				end
				if primaryHotkeyInput then
					playPhaseSet(self, self.PrimaryHotkeyInputPhaseSetName);
				end
				if auxiliaryHotkeyInput then
					playPhaseSet(self, self.AuxiliaryHotkeyInputPhaseSetName);
				end
			end
			
			if reloadInput then
				playPhaseSet(self, self.BlockInputPhaseSetName);
			end
		end
		
		-- Animation
		-- Rotation, absolute
		self.RotationTarget = self.RotationTargetOverride or self.RotationTarget;
		self.RotationTarget = self.RotationTarget - (self.AngVel * 4) + self.RotationTargetManualAddition;
		
		self.Rotation = self.Rotation + ((self.RotationTarget - self.Rotation) * math.min(1, TimerMan.DeltaTimeSecs * self.RotationSpeed))
		
		local total = math.rad(self.Rotation) * self.FlipFactor;
		self.InheritedRotAngleOffset = total * self.FlipFactor;
		
		-- Offsets, absolute
		self.JointOffset = self.JointOffset + (self.JointOffsetTarget - self.JointOffset) * math.min(1, TimerMan.DeltaTimeSecs * self.JointOffsetSpeed);
		self.SupportOffset = self.SupportOffset + (self.SupportOffsetTarget - self.SupportOffset) * math.min(1, TimerMan.DeltaTimeSecs * self.SupportOffsetSpeed);
		
		-- Handle temporary stance animation
		self.HorizontalAnim = math.floor(self.HorizontalAnim / (1 + TimerMan.DeltaTimeSecs * 24.0) * 1000) / 1000
		self.VerticalAnim = math.floor(self.VerticalAnim / (1 + TimerMan.DeltaTimeSecs * 15.0) * 1000) / 1000
		local stanceAnim = Vector()
		stanceAnim = stanceAnim + Vector(-1,0) * self.HorizontalAnim -- Horizontal animation
		stanceAnim = stanceAnim + Vector(0,5) * self.VerticalAnim -- Vertical animation
		
		-- Set stance, note relativity to original stance
		self.MordhauStanceOffset = self.MordhauStanceOffset + ((self.StanceOffsetTarget - self.MordhauStanceOffset) * math.min(1, TimerMan.DeltaTimeSecs * self.StanceOffsetSpeed));
		self.StanceOffset = Vector(self.OriginalStanceOffset.X, self.OriginalStanceOffset.Y) + stanceAnim + self.MordhauStanceOffset;
		self.SharpStanceOffset = Vector(self.OriginalStanceOffset.X, self.OriginalStanceOffset.Y) + stanceAnim + self.MordhauStanceOffset;
	else
		self.PlayingPhaseSet = false;
		self.CurrentPhase = 1;
	end
end

function SyncedUpdate(self)
	if self.LastHitTargetUniqueID and self.CurrentPhaseData then
		local hitTarget = MovableMan:FindObjectByUniqueID(self.LastHitTargetUniqueID);
		
		if self.CurrentPhaseData.canBeBlocked and hitTarget:IsInGroup("Weapons - Melee") then
			local messageTable = {};
			messageTable.senderUniqueID = self.UniqueID;
			messageTable.attackType = self.CurrentPhaseData.attackType;
			messageTable.hitPos = Vector(self.LastHitTargetPosition.X, self.LastHitTargetPosition.Y);
			hitTarget:SendMessage("Mordhau_ReceiveBlockableAttack", messageTable);
			-- At this point, if we were blocked, we have received a response
			if self.MessageReturn_BlockResponse then
				self.CurrentPhaseData.canBeBlocked = false;
				self.CurrentPhaseData.doesDamage = false;
				self.CurrentPhaseData.canBeBlockCancelled = true;
				
				if self.MessageReturn_BlockResponse == "Parried" then
					-- Guarantee that we buffer into a parry reaction				
					self.PhaseSetWasParried = true;
				end
				
				self.PhaseSetWasBlocked = true;
				self.MessageReturn_BlockResponse = false;
				return;
			end
		end
	
		if hitTarget:IsInGroup("Weapons - Melee") then
			-- Ignore this weapon for next rays and hopefully get to someone to hit
			self.WeaponIDToIgnore = hitTarget.ID;
			return;
		else	
			-- Otherwise, prepare to deal damage below
			self.CurrentPhaseData.canBeBlockCancelled = true;
		end
		
		if hitTarget and IsMOSRotating(hitTarget) then
			-- Check we haven't hit this target before by checking its parent
			if not self.HitMOTable[hitTarget:GetRootParent().UniqueID] then
				-- Add it for later
				self.HitMOTable[hitTarget:GetRootParent().UniqueID] = true;
				hitTarget = ToMOSRotating(hitTarget);
				hitTargetRootParent = hitTarget:GetRootParent();
				
				self.HitMOFunction(self, hitTarget, self.LastHitTargetPosition);
				
				local woundOffset = SceneMan:ShortestDistance(hitTarget.Pos, self.LastHitTargetPosition, SceneMan.SceneWrapsX);
				local woundAngle = woundOffset.AbsRadAngle - hitTarget.RotAngle;		
				local woundOffset = Vector(woundOffset.X * hitTarget.FlipFactor, woundOffset.Y):RadRotate(-hitTarget.RotAngle * hitTarget.FlipFactor):SetMagnitude(woundOffset.Magnitude);		
				local woundName = hitTarget:GetEntryWoundPresetName();
				
				local woundsToAdd = math.floor(self.CurrentPhaseData.Damage + math.random(0, 0.99));
				
				if woundName ~= "" then
					for i = 1, woundsToAdd do
						if IsAttachable(hitTarget) and self.CurrentPhaseData.dismemberInsteadOfGibbing and hitTarget.WoundCount + 2 >= hitTarget.GibWoundLimit and IsActor(hitTargetRootParent) then
							if ToAttachable(hitTarget):IsAttached() and (IsArm(hitTarget) or IsLeg(hitTarget) or (IsAHuman(hitTargetRootParent) and ToAHuman(hitTargetRootParent).Head and hitTarget.UniqueID == ToAHuman(hitTargetRootParent).Head.UniqueID)) then
								ToAttachable(hitTarget):RemoveFromParent(true, true);
								return;
							end
						end					
					
						local wound = CreateAEmitter(woundName);
						wound.DamageMultiplier = self.CurrentPhaseData.woundDamageMultiplier;
						wound.InheritedRotAngleOffset = woundAngle;
						wound.DrawAfterParent = true;
						hitTarget:AddWound(wound, woundOffset, true);
					end
				end
				
				if IsAHuman(hitTargetRootParent) then
					local human = ToAHuman(hitTargetRootParent);
					if human.EquippedItem then
						human.EquippedItem:SendMessage("Mordhau_HitFlinch");
					end
					if human.EquippedBGItem then
						human.EquippedBGItem:SendMessage("Mordhau_HitFlinch");
					end
				end
			end
		end
	end
end
