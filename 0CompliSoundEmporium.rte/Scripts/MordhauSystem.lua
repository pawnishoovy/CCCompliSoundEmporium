require("MasterTerrainIDList")

function OnMessage(self, message, object)
	if message == "Mordhau_ReceiveBlockableAttack" then
		local messageTable = {};
		if self.CurrentPhaseData then
			if self.CurrentPhaseData.parriesAttacks then
				messageTable.blockType = "Parried";
				MovableMan:FindObjectByUniqueID(object.senderUniqueID):SendMessage("Mordhau_MessageReturn_BlockResponse", messageTable);
				self.BlockFXFunction(self, object.attackType, object.hitPos);
				self.CurrentPhaseData.canBeBlockCancelled = true;
				self.CurrentPhaseData.allowsPhaseSetBuffering = true;
				self.CurrentPhaseData.canComboOut = true;
				self:SetNumberValue("Mordhau_AIParriedAnAttack", 1);			
				self.BlockStamina = math.min(self.BlockStaminaMaximum, self.BlockStamina + self.BlockStaminaParryReward);
			elseif self.CurrentPhaseData.blocksAttacks then
				self.BlockFXFunction(self, object.attackType, object.hitPos);
				self:SetNumberValue("Mordhau_AIBlockedAnAttack", 1);
				self.DoBlockAnim = true;
				self.BlockStamina = self.BlockStamina - ((5 * object.attackDamage * object.attackWoundDamageMultiplier) * self.BlockStaminaTakenDamageMultiplier);
				self.BlockStaminaRegenDelayTimer:Reset();
				if self.BlockStaminaEnabled and self.BlockStamina < (self.BlockStaminaMaximum * self.BlockStaminaFailureThresholdMultiplier) and self.Parent then
					messageTable.blockType = "NoStaminaBlocked";
					messageTable.noStaminaDamageMultiplier = self.BlockStaminaNoStaminaDamageMultiplier;
					MovableMan:FindObjectByUniqueID(object.senderUniqueID):SendMessage("Mordhau_MessageReturn_BlockResponse", messageTable);
					
					-- 20% grace amount for disarming
					if self.BlockStaminaDisarmInsteadOfNullifyingBlock and self.BlockStamina < ((self.BlockStaminaMaximum * self.BlockStaminaFailureThresholdMultiplier) - (self.BlockStaminaMaximum * 0.2)) then
						local vel = self.Parent.Vel;
						self:RemoveFromParent(true, true);
						self.Vel = vel + Vector(-5 * self.FlipFactor, -10);
						self.AngularVel = 10 * self.FlipFactor;
						if self.DisarmSound then
							self.DisarmSound:Play(self.Pos);
						end
					end
				else
					messageTable.blockType = "Blocked";
					MovableMan:FindObjectByUniqueID(object.senderUniqueID):SendMessage("Mordhau_MessageReturn_BlockResponse", "Blocked");
				end
				self.BlockStamina = math.max(0, self.BlockStamina);
			end
		end
	elseif message == "Mordhau_MessageReturn_BlockResponse" then
		self.MessageReturn_BlockResponse = object;
		self.BeingBlockedFXFunction(self);
	elseif message == "Mordhau_HitFlinch" then
		if self.PlayingPhaseSet then
			if self.CurrentPhaseData then
				self.CurrentPhaseData.canBeBlockCancelled = true;
			end
			if not self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet then
				self.FlinchCooldownTimer:Reset();
				self.PlayingPhaseSet = false;
				self.ReloadInputNullifyForAttack = false;
			end
		end
	elseif message == "Mordhau_AIRequestWeaponInfo" then
		if self.Parent then
			messageTable = {};
			messageTable.validAttackPhaseSets = self.ValidAIAttackPhaseSets;
			messageTable.allPhaseSets = self.PhaseSets;
			self.Parent:SendMessage("Mordhau_AIWeaponInfoResponse", messageTable);
		else
			-- who the hell sent us the message?
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
		
		-- Values for AI to work with
		local phaseSet = getPhaseSetByName(self, name);
		if phaseSet.isAttackingPhaseSet then
			self:SetNumberValue("Mordhau_AIWeaponCurrentlyAttacking", 1);
			self:SetNumberValue("Mordhau_AIWeaponCurrentRange", phaseSet.AIRange);
		else
			self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyAttacking");
			self:RemoveNumberValue("Mordhau_AIWeaponCurrentRange");
		end
		
		-- Clear AI values
		self:RemoveNumberValue("Mordhau_AIBlockedAnAttack");
		self:RemoveNumberValue("Mordhau_AIParriedAnAttack");
	
		self.MessageReturn_BlockResponse = nil;
		self.PhaseSetWasBlocked = false;
		self.PhaseSetWasParried = false;
		self.PhaseSetWasInterruptedByTerrain = false;
		self.WeaponIDToIgnore = nil;
		self.HFlipSwitches = 0;
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
	
	-- Default HitMOFXFunction. Handles Slash/Stab, Metal/Flesh, among other things.
	if not self.HitMOFXFunction then
		self.HitMOFXFunction = function (self, hitTarget, hitPos)
			local hitType;		
			local woundName = hitTarget:GetEntryWoundPresetName();
			local material = hitTarget.Material.PresetName;
			
			if string.find(material,"Flesh") or string.find(woundName,"Flesh") then
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
	
	-- Default BeingBlockedFX function. Just plays one sound.
	if not self.BeingBlockedFXFunction then
		self.BeingBlockedFXFunction = function (self)
			self.HitSFX.BeingBlocked:Play(self.Pos);
		end
	end
	
	-- Default BlockFX function. Handles Stab/Slash, Heavy attacks, and parrying FX.
	if not self.BlockFXFunction then
		self.BlockFXFunction = function (self, attackType, hitPos)
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
				if self.BlockSFX.HeavyBlockAdd then
					self.BlockSFX.HeavyBlockAdd:Play(self.Pos);
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
					local effect = self.BlockGFX.ParryAdd:Clone();
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
	
	self.ParriedCooldownTimer = Timer();
	
	self.BlockStaminaEnabled = self.BlockStaminaMaximum > 0;
	
	self.BlockStamina = self:NumberValueExists("Mordhau_BlockStamina") and self:GetNumberValue("Mordhau_BlockStamina") or self.BlockStaminaMaximum
	self:RemoveNumberValue("Mordhau_BlockStamina");	
	
	self.BlockStaminaRegenDelayTimer = Timer();
	
	self.BlockStaminaRegenDelay = 500;
	
	self.EffectiveWoundCount = self:NumberValueExists("Mordhau_EffectiveWoundCount") and self:GetNumberValue("Mordhau_EffectiveWoundCount") or self.WoundCount;
	self:RemoveNumberValue("Mordhau_EffectiveWoundCount");
	
	self.GibWoundLimit = 999;
	
	self.LastWoundCount = self.WoundCount;

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
	
	self.HFlipSwitches = 0;
	
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
	
	-- Normal creation has OnAttach happen properly, but reloading scripts clears the Lua state (and thus the parent) without running OnAttach again, but this will run and fix it
	local rootParent = self:GetRootParent();
	if IsAHuman(rootParent) then
		self.Parent = ToAHuman(rootParent);
		self.ParentController = self.Parent:GetController();
		if not self.Parent:HasScript("0CompliSoundEmporium.rte/Scripts/MordhauMeleeAI.lua") then
			self.Parent:AddScript("0CompliSoundEmporium.rte/Scripts/MordhauMeleeAI.lua");
		end
	end
end

function OnAttach(self, newParent)
	if IsAHuman(newParent:GetRootParent()) then
		self.Parent = ToAHuman(newParent:GetRootParent());
		self.ParentController = self.Parent:GetController();
		if not self.Parent:HasScript("0CompliSoundEmporium.rte/Scripts/MordhauMeleeAI.lua") then
			self.Parent:AddScript("0CompliSoundEmporium.rte/Scripts/MordhauMeleeAI.lua");
		end
		
		if not self.EquippedOffTheGround then
			playPhaseSet(self, self.EquipPhaseSetName);
		end
		
		self.BlockStamina = self.BlockStaminaMaximum;
		
		self.HUDVisible = false;
	end
end

function OnDetach(self)
	-- TODO: not this
	self.HUDVisible = false;

	self.Frame = self.IdleFrame;
	self.Parent = nil;
	self.ParentController = nil;
	
	self.PlayingPhaseSet = false;
	self.CurrentPhaseData = nil;
	
	-- Clear AI values, just in case
	
	self:RemoveNumberValue("Mordhau_AIBlockInput");
	self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyAttacking");
	self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyBlockable");
	self:RemoveNumberValue("Mordhau_AIWeaponCurrentRange");
	self:RemoveNumberValue("Mordhau_AIBlockedAnAttack");
	self:RemoveNumberValue("Mordhau_AIParriedAnAttack");		
end

function ThreadedUpdate(self)
	if self.DisarmSound then
		self.DisarmSound.Pos = self.Pos;
	end

	self.AngVel = 0;
	self.HorizontalAnim = 0;
	self.VerticalAnim = 0;
	
	if self.DoBlockAnim then
		self.DoBlockAnim = false;
		self.AngVel = self.BlockAngVel;
		self.HorizontalAnim = -1;
	end
	
	-- Should not be required, but sometimes gibbing crashes due to this somehow..
	if not MovableMan:ValidMO(self.Parent) then
		self.Parent = nil;
	end

	if self.Parent and self.PlayingPhaseSet and self.CanParryBullets and self.CurrentPhaseData and self.CurrentPhaseData.parriesAttacks then
		-- Ignore incoming wounds, play parry sound for every parried bullet if applicable
		if self.WoundCount > self.LastWoundCount then
			if self.BlockSFX.ParryAdd then
				self.BlockSFX.ParryAdd:Play(self.Pos);
			end
			self.CurrentPhaseData.canBeBlockCancelled = true;
			self.CurrentPhaseData.allowsPhaseSetBuffering = true;
			self.CurrentPhaseData.canComboOut = true;
			self.AngVel = self.BlockAngVel;
		end
	else
		if self.WoundCount > self.LastWoundCount then
			self.EffectiveWoundCount = self.EffectiveWoundCount + (self.WoundCount - self.LastWoundCount);
			self.AngVel = self.BlockAngVel;
			self.HorizontalAnim = -1;
		end
	end

	if self.Parent then
		local isPlayerControlled = self.Parent:IsPlayerControlled();

		local primaryInput = self:IsActivated();
		local primaryHotkeyInput = self:HotkeyActionIsActivated(HeldDevice.PRIMARYHOTKEY);
		local auxiliaryHotkeyInput = self:HotkeyActionIsActivated(HeldDevice.AUXILIARYHOTKEY);
		local anyAttackInput = primaryInput or primaryHotkeyInput or auxiliaryHotkeyInput;
		
		-- TODO: fix this mess
		local reloadInput;
		local heldReloadInput;
		reloadInput = self.ParentController:IsState(Controller.WEAPON_RELOAD) 
		heldReloadInput = isPlayerControlled and UInputMan:KeyHeld(Key.R);
		
		-- Make attacking from a block not risk just insta-block-cancelling
		if reloadInput and anyAttackInput and not self.PhaseSetWasBlocked then
			self.ReloadInputNullifyForAttack = true;
		elseif not reloadInput then
			self.ReloadInputNullifyForAttack = false;
		end
		
		-- Nullify as mentioned
		if self.ReloadInputNullifyForAttack then
			reloadInput = false;
			heldReloadInput = false;
		end
		
		local aiAttackPhaseSetName;
		if self:StringValueExists("Mordhau_AIAttackPhaseSetInput") then
			aiAttackPhaseSetName = self:GetStringValue("Mordhau_AIAttackPhaseSetInput");
			self:RemoveStringValue("Mordhau_AIAttackPhaseSetInput");
		end
		
		if self:NumberValueExists("Mordhau_AIBlockInput") and not isPlayerControlled then
			heldReloadInput = true;
		end
		
		-- TODO: real AI
		if primaryInput and not isPlayerControlled then
			if math.random(0, 100) > 66 then
				primaryHotkeyInput = true;
				primaryInput = false;
			elseif math.random(0, 100) < 33 then
				auxiliaryHotkeyInput = true;
				primaryInput = false;
			end
		end
	
		-- Phase handling
		if self.PlayingPhaseSet then	
			if self.HFlipped ~= self.LastHFlipped then
				self.HFlipSwitches = self.HFlipSwitches + 1;
			end
		
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
				-- Reset WasInterruptedByTerrain if this phase Cleaves, otherwise turn off damage
				if self.PhaseSetWasInterruptedByTerrain then
					if self.CurrentPhaseData.Cleaves then
						self.PhaseSetWasInterruptedByTerrain = false;
					else
						self.CurrentPhaseData.doesDamage = false;
					end
				end
				-- Allow blocking for all phases of a PhaseSet if we hit anything
				if self.PhaseSetWasBlocked or self.PhaseSetWasParried or self.PhaseSetWasInterruptedByTerrain then
					self.CurrentPhaseData.canBeBlockCancelled = true;
				end
				-- If this is after our final attack phase, let AI know
				if self.CurrentPhaseData.isAfterFinalAttackPhase then
					self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyAttacking");
				end
			end
			
			if self.CurrentPhaseData.soundStart and not self.CurrentPhaseStartSoundPlayed then
				self.CurrentPhaseData.soundStart:Play(self.Pos);
				self.CurrentPhaseStartSoundPlayed = true;
			end
			
			-- TODO: remove this, irrelevant?
			-- Disable blocking if we're under the required stamina.
			if self.BlockStaminaEnabled then
				--if self.BlockStamina < (self.BlockStaminaMaximum * self.BlockStaminaFailureThresholdMultiplier) then
				--	self.CurrentPhaseData.blocksAttacks = false;
				--end
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
				if reloadInput and not self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet then
					self.BufferedPhaseSet = self.BlockInputPhaseSetName;
				end
				if aiAttackPhaseSetName then
					self.BufferedPhaseSet = aiAttackPhaseSetName;
				end
			else
				self.BufferedPhaseSet = false;
			end
			
				
			-- Collision logic
			-- Disable collision altogether if we aren't Cleaves == true and we've already hit someone
			local wasCollidable = false;
			if self.CurrentPhaseData.Cleaves or not next(self.HitMOTable) then
				if self.CurrentPhaseData.canBeBlocked or self.CurrentPhaseData.doesDamage and not self.PhaseSetWasBlocked then	
					wasCollidable  = true;				
					self:SetNumberValue("Mordhau_AIWeaponCurrentlyBlockable", 1);
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
							
							-- Prepare to check this collision later this frame
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
										
										-- Stop soundStart if applicable	
										if self.CurrentPhaseData.soundStart and self.CurrentPhaseData.soundStartStopsOnHit and self.CurrentPhaseData.soundStart:IsBeingPlayed() then
											self.CurrentPhaseData.soundStart:FadeOut(100);
										end	
										
										self.PhaseSetWasInterruptedByTerrain = true;
										break;
									end
								end
							end
						end			
									
						rayPos = rayPos + vecBetweenRays;
					end
				end
			end			
			
			if not wasCollidable then
				self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyBlockable");
			end
			
			-- Callback
			self.CurrentPhaseData.constantCallback(self);
		
			if self.PhaseSetWasParried then
				self.BufferedPhaseSet = "Parried Reaction PhaseSet";
				self.CurrentPhaseData.canComboOut = true;
				self.ParriedCooldownTimer:Reset();
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
					-- Don't be as smooth if the buffered PhaseSet is a blocking one, we wanna get in position ASAP
					pseudoPhase.frameStart = self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet and self.PhaseSets[self.CurrentPhaseSet].frameStart or self.Frame;
					pseudoPhase.angleStart = self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet and self.PhaseSets[self.CurrentPhaseSet].angleStart or self.RotationTarget;
					pseudoPhase.stanceStart = self.PhaseSets[self.CurrentPhaseSet].isBlockingPhaseSet and self.PhaseSets[self.CurrentPhaseSet].stanceStart or self.StanceOffsetTarget;
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
			
			-- Make sure we're not over our HFlipSwitch limit
			if self.PhaseSets[self.CurrentPhaseSet].HFlipSwitchLimit > -1 then
				if self.HFlipSwitches > self.PhaseSets[self.CurrentPhaseSet].HFlipSwitchLimit then
					-- Simulate a flinch
					self.FlinchCooldownTimer:Reset();
					self.PlayingPhaseSet = false;
				end
			end
			
			-- Block bullets if appropriate
			if self.CanBlockBullets or self.CanParryBullets then 
				if self.CurrentPhaseData.blocksAttacks or self.CurrentPhaseData.parriesAttacks then
					self.GetsHitByMOsWhenHeld = true;
				else
					self.GetsHitByMOsWhenHeld = false;
				end
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
			self.Frame = self.IdleFrame;
			self.RotationSpeed = self.IdleRotationSpeed * 60;
			self.RotationTarget = self.IdleRotation;
			self.JointOffsetTarget = self.OriginalJointOffset;
			self.SupportOffsetTarget = self.OriginalSupportOffset;
			self.StanceOffsetTarget = Vector(0, 0);
			
			if self.FlinchCooldownTimer:IsPastSimMS(self.FlinchCooldown) and self.ParriedCooldownTimer:IsPastSimMS(self.ParryCooldown) then
				-- Player input
				if isPlayerControlled then
					if primaryInput then
						playPhaseSet(self, self.PrimaryInputPhaseSetName);
					end
					if primaryHotkeyInput then
						playPhaseSet(self, self.PrimaryHotkeyInputPhaseSetName);
					end
					if auxiliaryHotkeyInput then
						playPhaseSet(self, self.AuxiliaryHotkeyInputPhaseSetName);
					end
				else
					-- AI inputs via StringValue above
					if aiAttackPhaseSetName then
						playPhaseSet(self, aiAttackPhaseSetName);
					end
				end
			end
			
			if reloadInput then
				playPhaseSet(self, self.BlockInputPhaseSetName);
			end
			
			self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyAttacking");
			self:RemoveNumberValue("Mordhau_AIWeaponCurrentlyBlockable");
			self:RemoveNumberValue("Mordhau_AIWeaponCurrentRange");
		end
		
		-- Block stamina
		if self.BlockStaminaRegenDelayTimer:IsPastSimMS(self.BlockStaminaRegenDelay) then
			self.BlockStamina = math.min(self.BlockStaminaMaximum, self.BlockStamina + TimerMan.DeltaTimeSecs * self.BlockStaminaRegenRate);
		end
		
		-- Block stamina bar
		if (isPlayerControlled or self.DrawBlockStaminaBarForAI) and self.BlockStaminaEnabled and self.DrawBlockStaminaBar then
			local hudOrigin = self.Parent.AboveHUDPos;
			
			local hudBarWidthOutline = 30;
			local hudBarWidth = 30;
			local hudBarHeight = 3;
			local hudBarColor = 87;
			local hudBarColorBG = 83;
			local hudBarColorOutline = 2;
			
			local hudBarOffset = Vector(1, 1);
			
			local hudBarWidth = 30 * (self.BlockStamina / self.BlockStaminaMaximum);

			hudBarColor = self.BlockStamina > (self.BlockStaminaMaximum * self.BlockStaminaFailureThresholdMultiplier) and 87 or 47;

			PrimitiveMan:DrawBoxFillPrimitive(hudOrigin + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), hudOrigin + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorBG);
			PrimitiveMan:DrawBoxFillPrimitive(hudOrigin + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), hudOrigin + Vector(hudBarWidthOutline * -0.5 + hudBarWidth, hudBarHeight * 0.5), hudBarColor);
			PrimitiveMan:DrawBoxPrimitive(hudOrigin + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), hudOrigin + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorOutline)
			
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
	
	if self:IsAttached() then
		self.EquippedOffTheGround = false;
	else
		self.EquippedOffTheGround = true;
	end
	
	if self.EffectiveWoundCount >= self.RealGibWoundLimit then
		self:GibThis();
	end
	
	self.LastWoundCount = self.WoundCount;
	self.LastHFlipped = self.HFlipped;
end

function SyncedUpdate(self)
	if self.LastHitTargetUniqueID and self.CurrentPhaseData then
		local hitTarget = MovableMan:FindObjectByUniqueID(self.LastHitTargetUniqueID);
		if self.CurrentPhaseData.canBeBlocked and hitTarget:IsInGroup("Weapons - Melee") then
			local messageTable = {};
			messageTable.senderUniqueID = self.UniqueID;
			messageTable.attackType = self.CurrentPhaseData.attackType;
			messageTable.attackDamage = self.CurrentPhaseData.Damage;
			messageTable.attackWoundDamageMultiplier = self.CurrentPhaseData.woundDamageMultiplier;
			messageTable.hitPos = Vector(self.LastHitTargetPosition.X, self.LastHitTargetPosition.Y);
			hitTarget:SendMessage("Mordhau_ReceiveBlockableAttack", messageTable);
			-- At this point, if we were blocked, we have received a response
			if self.MessageReturn_BlockResponse then
				if self.MessageReturn_BlockResponse.blockType ~= "NoStaminaBlocked" then
					self.CurrentPhaseData.canBeBlocked = false;
					self.CurrentPhaseData.doesDamage = false;
					self.CurrentPhaseData.canBeBlockCancelled = true;
					
					self.ReloadInputNullifyForAttack = false;
					
					if self.MessageReturn_BlockResponse.blockType == "Parried" then
						-- Guarantee that we buffer into a parry reaction				
						self.PhaseSetWasParried = true;
					end
					
					self.PhaseSetWasBlocked = true;
					self.MessageReturn_BlockResponse = nil;
					return;
				else
					self.CurrentPhaseData.Damage = math.max(1, self.CurrentPhaseData.Damage * self.MessageReturn_BlockResponse.noStaminaDamageMultiplier);
					self.CurrentPhaseData.woundDamageMultiplier = self.CurrentPhaseData.woundDamageMultiplier * self.MessageReturn_BlockResponse.noStaminaDamageMultiplier;
				end
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
				
				self.HitMOFXFunction(self, hitTarget, self.LastHitTargetPosition);
				
				self.BlockStamina = math.min(self.BlockStaminaMaximum, self.BlockStamina + self.BlockStaminaHitMOReward);
				
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
					human:SendMessage("Mordhau_HitFlinch");
					if human.EquippedItem then
						human.EquippedItem:SendMessage("Mordhau_HitFlinch");
					end
					if human.EquippedBGItem then
						human.EquippedBGItem:SendMessage("Mordhau_HitFlinch");
					end
				end
				
				-- Stop soundStart if applicable	
				if self.CurrentPhaseData.soundStart and self.CurrentPhaseData.soundStartStopsOnHit and self.CurrentPhaseData.soundStart:IsBeingPlayed() then
					self.CurrentPhaseData.soundStart:FadeOut(100);
				end	
			end
		end
	end
end

function OnSave(self)
	self:SetNumberValue("Mordhau_EffectiveWoundCount", self.EffectiveWoundCount);
	self:SetNumberValue("Mordhau_BlockStamina", self.EffectiveWoundCount);
end