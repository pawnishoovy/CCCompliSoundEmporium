function Sign(x)
	if x<0 then
		return -1
	elseif x>0 then
		return 1
	else
		return 0
	end
end

-- for actor in MovableMan.Actors do actor.HUDVisible = false end

function OnMessage(self, message, object)
	if message == "Mordhau_AIWeaponInfoResponse" then
		-- Copy over info, match names, etc
		for index, name in pairs(object.validAttackPhaseSets) do
			self.MeleeAI.weaponInfo.validAttackPhaseSets[index] = {};
			self.MeleeAI.weaponInfo.validAttackPhaseSets[index].Name = name;
		end
		
		for index, phaseSetTable in pairs(object.allPhaseSets) do
			for index2, validAttackPhaseSetTable in pairs(self.MeleeAI.weaponInfo.validAttackPhaseSets) do
				if phaseSetTable.Name == validAttackPhaseSetTable.Name then
					validAttackPhaseSetTable.AIRange = phaseSetTable.AIRange;
				end
			end
		end
		-- Officialize it
		self.MeleeAI.weapon = self.EquippedItem;
	elseif message == "Mordhau_HitFlinch" then
	
	end
end

function Create(self)
	
	self.MeleeAI = {}
	self.MeleeAI.debug = false;
	self.MeleeAI.active = false;

	self.MeleeAI.skill = self.MeleeAISkill or 1; -- Diagnosis: skill issue
	self.MeleeAI.active = false;
	
	local activity = ActivityMan:GetActivity();
	if activity then
		self.MeleeAI.skill = (self.MeleeAI.skill / 2) + ((self.MeleeAI.skill / 2) * (activity:GetTeamAISkill(self.Team)/100));
	end
	
	-- Percentage of the time that, after any block, AI will try to parry next time it blocks.
	self.MeleeAI.parryChance = 90 * self.MeleeAI.skill; --%
	self.MeleeAI.attemptingParry = false;
	
	self.MeleeAI.movementInputPrevious = 0;
	self.MeleeAI.movementDirectionChangeTimer = Timer();
	self.MeleeAI.movementDirectionChangeDuration = 100;
	
	self.MeleeAI.weapon = nil;
	self.MeleeAI.weaponInfo = {};
	self.MeleeAI.weaponInfo.validAttackPhaseSets = {};
	self.MeleeAI.weaponNextAttackPhaseSetIndex = 1;
	
	self.MeleeAI.distanceOffsetMin = -15
	self.MeleeAI.distanceOffsetMax = 30
	self.MeleeAI.distanceOffset = RangeRand(self.MeleeAI.distanceOffsetMin, self.MeleeAI.distanceOffsetMax)
	self.MeleeAI.distanceOffsetDelayTimer = Timer()
	self.MeleeAI.distanceOffsetDelayMin = 700
	self.MeleeAI.distanceOffsetDelayMax = 2200
	self.MeleeAI.distanceOffsetDelay = RangeRand(self.MeleeAI.distanceOffsetDelayMin, self.MeleeAI.distanceOffsetDelayMax)
	
	self.MeleeAI.blocking = false
	self.MeleeAI.blockingDelayMax = 600 * (0.15 + 0.85 * (1 - self.MeleeAI.skill))
	self.MeleeAI.blockingDelay = self.MeleeAI.blockingDelayMax * 0.05
	self.MeleeAI.blockingDelayTimer = Timer()
	self.MeleeAI.blockingFatigueLevel = 1
	self.MeleeAI.blockingFatigueLevelRegeneration = (0.15 + 0.85 * self.MeleeAI.skill)
	self.MeleeAI.blockingFatigueMode = 0 -- 0 - ready, 1 - blocking, 2 - regenerating
	
	self.MeleeAI.tactics = {
		["Offensive"] = function ()
			self.MeleeAI.distanceOffset = math.abs(self.MeleeAI.distanceOffset) - 20;
		end,
		["Defensive"] = function ()
			-- Basic behaviour
		end,
		["Retreat"] = function ()
			self.MeleeAI.distanceOffset = math.abs(self.MeleeAI.distanceOffset) + 60;
		end
	}
	self.MeleeAI.tactic = "Offensive"
	
	self.MeleeAI.attacking = false
	
	self.MeleeAI.attackOpportunityMissThreshold = 0
	self.MeleeAI.attackOpportunityMissThresholdGain = 15 * (1 - self.MeleeAI.skill)
	self.MeleeAI.attackOpportunityMissDelay = 1000
	self.MeleeAI.attackOpportunityMissTimer = Timer()
	
end

function ThreadedUpdateAI(self)

	if self.Status >= Actor.DYING or not self.Head then
		return
	end
	self.MeleeAI.attacking = false
	
	local ctrl = (self.controller and self.controller or self:GetController())
	
	-- Misc
	local movementInput = 0
	
	local weapon = self.EquippedItem;
	if weapon and weapon:IsInGroup("Weapons - Mordhau Melee") then
		if (not self.MeleeAI.weapon) or weapon.UniqueID ~= self.MeleeAI.weapon.UniqueID then
			self.SyncedRequestWeaponInfo = true;
			self:RequestSyncedUpdate();
		end
	elseif self.MeleeAI.weapon ~= nil then
		self.MeleeAI.weapon = nil
		self.MeleeAI.weaponInfo = {}
	end
	
	
	
	-- Fatigue "state" machine
	if self.MeleeAI.blockingFatigueMode == 0 then -- Read
		self.MeleeAI.blockingFatigueLevel = math.min(self.MeleeAI.blockingFatigueLevel + TimerMan.DeltaTimeSecs * self.MeleeAI.blockingFatigueLevelRegeneration * 0.25, 1)
		if self.MeleeAI.blocking and not self.MeleeAI.attacking then
			self.MeleeAI.blockingFatigueMode = 1
		end
	elseif self.MeleeAI.blockingFatigueMode == 1 then -- Blocking
		self.MeleeAI.blockingFatigueLevel = math.max(self.MeleeAI.blockingFatigueLevel - TimerMan.DeltaTimeSecs * 1.0, 0)
		if not self.MeleeAI.blocking or self.MeleeAI.attacking then
			self.MeleeAI.blockingFatigueMode = 0
		elseif self.MeleeAI.blockingFatigueLevel < 0.05 then
			self.MeleeAI.blockingFatigueMode = 2
		end
	elseif self.MeleeAI.blockingFatigueMode == 2 then -- Regeneration (cooldown)
		self.MeleeAI.blockingFatigueLevel = math.min(self.MeleeAI.blockingFatigueLevel + TimerMan.DeltaTimeSecs * self.MeleeAI.blockingFatigueLevelRegeneration, 1)
		if self.MeleeAI.blockingFatigueLevel > 0.95 then
			self.MeleeAI.blockingFatigueMode = 0
		end
	end
	
	
	-- Extra graphical debug
	if self.MeleeAI.debug then
		--self.MeleeAI.blockingFatigueLevel = 0
		--self.MeleeAI.blockingFatigueLevelRegeneration = 1
		--self.MeleeAI.blockingFatigueMode = 0 -- 0 - ready, 1 - blocking, 2 - regenerating
		
		local hudOrigin = self.Pos
		local hudUpperPos = hudOrigin + Vector(0, -30)
		
		local hudBarWidthOutline = 30
		local hudBarWidth = 30
		local hudBarHeight = 3
		local hudBarColor = 87
		local hudBarColorBG = 83
		local hudBarColorOutline = 2
		
		local hudBarOffset = Vector(1, 1)
		
		local pos = hudUpperPos
		
		-- Fatigue
		hudBarWidth = 30 * self.MeleeAI.blockingFatigueLevel
		hudBarColor = ((self.MeleeAI.blockingFatigueMode == 0 and 87) or (self.MeleeAI.blockingFatigueMode == 1 and 99 or 47))
		hudBarColorBG = 83

		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5) + hudBarOffset, pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5) + hudBarOffset, hudBarColorBG)
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * -0.5 + hudBarWidth, hudBarHeight * 0.5), hudBarColor)
		PrimitiveMan:DrawBoxPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorOutline)
		
		pos = pos + Vector(0, 5)
		
		hudBarWidth = 30 * math.max(self.MeleeAI.attackOpportunityMissThreshold / 100, 1 - math.min(self.MeleeAI.attackOpportunityMissTimer.ElapsedSimTimeMS / self.MeleeAI.attackOpportunityMissDelay, 1))
		hudBarColor = 213
		hudBarColorBG = 216
		
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5) + hudBarOffset, pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5) + hudBarOffset, hudBarColorBG)
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * -0.5 + hudBarWidth, hudBarHeight * 0.5), hudBarColor)
		PrimitiveMan:DrawBoxPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorOutline)
	end
	
	local target = self.AI.Target
	if target and (self.MeleeAI.weapon) then
	
		local dist = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX);
		local distanceToTarget = dist.Magnitude;
		
		ctrl:SetState(Controller.BODY_CROUCH, false);
		ctrl:SetState(Controller.BODY_PRONE, false);
		
		if (self.AI.TargetLostTimer.ElapsedSimTimeMS < 5000 and distanceToTarget < 200) or distanceToTarget < 100 then	
			self.MeleeAI.active = true
			
			if self.MeleeAI.debug then
				PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, 13)
				PrimitiveMan:DrawCircleFillPrimitive(target.Pos, 2, 13)
				
				PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + dist, 13);
			end
			
			local nextAttackRange = 50;
			
			-- Randomize distance form target
			if self.MeleeAI.distanceOffsetDelayTimer:IsPastSimMS(self.MeleeAI.distanceOffsetDelay) then
				self.MeleeAI.distanceOffset = RangeRand(self.MeleeAI.distanceOffsetMin, self.MeleeAI.distanceOffsetMax)
				self.MeleeAI.distanceOffsetDelay = RangeRand(self.MeleeAI.distanceOffsetDelayMin, self.MeleeAI.distanceOffsetDelayMax)
				self.MeleeAI.distanceOffsetDelayTimer:Reset()
				
				local tacticList = {}
				for key, tactic in pairs(self.MeleeAI.tactics) do
					table.insert(tacticList, key)
				end
				self.MeleeAI.tactic = tacticList[math.random(1, #tacticList)]
			end			
			
			local targetWeapon;
			local targetWeaponMelee;
			
			local tryingToBlock;
			
			--- Human enemy behavior
			local didCompatibleBehavior = false;
			if IsAHuman(target) then
				target = ToAHuman(target)
				
				ctrl:SetState(Controller.WEAPON_FIRE, false);
				self.AI.fire = false;
				
				local range = self.MeleeAI.weaponInfo.validAttackPhaseSets[self.MeleeAI.weaponNextAttackPhaseSetIndex].AIRange + 30;
				nextAttackRange = newRange and newRange or 50;
				
				targetWeapon = target.EquippedItem
				targetWeaponMelee = false
				
				-- See if our target has a MordhauSystem weapon
				if targetWeapon and targetWeapon:IsInGroup("Weapons - Mordhau Melee") then
					targetWeaponMelee = true;
				end	
				
				-- Compatible melee enemy behavior
				if targetWeaponMelee then	
					didCompatibleBehavior = true;
				
					local targetIsMeleeAttacking = targetWeapon:NumberValueExists("Mordhau_AIWeaponCurrentlyAttacking");
					local targetMeleeAttackRange;				
					if targetIsMeleeAttacking then
						targetMeleeAttackRange = targetWeapon:GetNumberValue("Mordhau_AIWeaponCurrentRange");
					end
					
					if self.MeleeAI.weapon:NumberValueExists("Mordhau_AIParriedAnAttack") then
						self.MeleeAI.successfulParry = true;
						self.MeleeAI.weapon:RemoveNumberValue("Mordhau_AIParriedAnAttack");			
					end					
					
					-- Defend if appropriate
					if (not self.MeleeAI.successfulParry) and (targetIsMeleeAttacking) and (distanceToTarget < (targetMeleeAttackRange + 60)) and (self.FlipFactor ~= target.FlipFactor) and (self.MeleeAI.blockingFatigueMode < 2) and (not self.MeleeAI.parrySuccess) then
						tryingToBlock = true;
						
						if self.MeleeAI.blockingDelayTimer:IsPastSimMS(self.MeleeAI.blockingDelay) or self.MeleeAI.attemptingParry then
						
							if (not self.MeleeAI.attemptingParry) or targetWeapon:NumberValueExists("Mordhau_AIWeaponCurrentlyBlockable") then		
								-- Block input
								ctrl:SetState(Controller.WEAPON_RELOAD, true);
								self.MeleeAI.weapon:SetNumberValue("Mordhau_AIBlockInput", 1);
									
								if not self.MeleeAI.blocking then
									self.MeleeAI.blocking = true
								end
							end
						end	
					else -- End of block
						self.MeleeAI.blockingDelayTimer:Reset()
						
						self.MeleeAI.weapon:RemoveNumberValue("Mordhau_AIBlockInput");
						
						if self.MeleeAI.blocking then
							self.MeleeAI.blocking = false
							self.MeleeAI.attackOpportunityMissThreshold = self.MeleeAI.attackOpportunityMissThreshold + self.MeleeAI.attackOpportunityMissThresholdGain * 0.5
							
							self.MeleeAI.blockingDelay = self.MeleeAI.blockingDelayMax * RangeRand(0.1, 1.0) * RangeRand(0.5, 1.0)
							
							if math.random(0, 100) < self.MeleeAI.parryChance then
								self.MeleeAI.attemptingParry = true;
							else
								self.MeleeAI.attemptingParry = false;
							end
						end
					end
					
					-- Try to attack if not blocking, or if we just parried an attack
					if ((not tryingToBlock) and self.MeleeAI.attackOpportunityMissTimer:IsPastSimMS(self.MeleeAI.attackOpportunityMissDelay)) or self.MeleeAI.successfulParry then			
						-- Always be offensive during attacks
						self.MeleeAI.tactic = "Offensive";
					
						if RangeRand(0, 100) < self.MeleeAI.attackOpportunityMissThreshold and not self.MeleeAI.successfulParry then -- Attack miss Threshold handling
							self.MeleeAI.attackOpportunityMissThreshold = -self.MeleeAI.attackOpportunityMissThresholdGain
							self.MeleeAI.attackOpportunityMissTimer:Reset()
						elseif distanceToTarget < (nextAttackRange + math.random(-5,5) + 10) or self.MeleeAI.successfulParry then
							-- Initiate our next attack
							local phaseSetName = self.MeleeAI.weaponInfo.validAttackPhaseSets[self.MeleeAI.weaponNextAttackPhaseSetIndex].Name;
							self.MeleeAI.weapon:SetStringValue("Mordhau_AIAttackPhaseSetInput", phaseSetName);
							-- Randomize next attack
							self.MeleeAI.weaponNextAttackPhaseSetIndex = math.floor(math.random(1, #self.MeleeAI.weaponInfo.validAttackPhaseSets));
							
							-- Increase miss Threshold
							self.MeleeAI.attackOpportunityMissThreshold = self.MeleeAI.attackOpportunityMissThreshold + self.MeleeAI.attackOpportunityMissThresholdGain
						end
						self.MeleeAI.successfulParry = false;
					end
				end
			end
			
			self.MeleeAI.tactics[self.MeleeAI.tactic]()
			
			-- Incompatible, or ranged, enemy behavior
			if not didCompatibleBehavior then
				self.MeleeAI.distanceOffset = -20
				
				-- Defend if far
				if distanceToTarget >= (nextAttackRange + 20) then
					local enemyCtrl = target:GetController()
					if enemyCtrl then
						local frequency = 800
						if (target.Age % frequency) < frequency * 0.7 and enemyCtrl:IsState(Controller.WEAPON_FIRE) then
							ctrl:SetState(Controller.WEAPON_RELOAD, true);
							self.MeleeAI.weapon:SetNumberValue("Mordhau_AIBlockInput", 1);
						end
					end
				else
					-- Just go hogwild if close
					local phaseSetName = self.MeleeAI.weaponInfo.validAttackPhaseSets[self.MeleeAI.weaponNextAttackPhaseSetIndex].Name;
					self.MeleeAI.weapon:SetStringValue("Mordhau_AIAttackPhaseSetInput", phaseSetName);
					-- Randomize next attack
					self.MeleeAI.weaponNextAttackPhaseSetIndex = math.floor(math.random(1, #self.MeleeAI.weaponInfo.validAttackPhaseSets));
				end
			end
			
			-- Movement
			local distanceToKeep = nextAttackRange + self.MeleeAI.distanceOffset
			if math.abs(dist.X) > (distanceToKeep - 7) then
				movementInput = Sign(dist.X)
			elseif math.abs(dist.X) < (distanceToKeep - 5) then
				movementInput = -Sign(dist.X)
			end
			
			if distanceToTarget < 120 then
				ctrl:SetState(Controller.BODY_JUMP, false)
				ctrl:SetState(Controller.BODY_JUMPSTART, false)
			end
			if movementInput ~= 0 then
				if self.MeleeAI.movementInputPrevious ~= movementInput then
					self.MeleeAI.movementInputPrevious = movementInput
					self.MeleeAI.movementDirectionChangeTimer:Reset()
				end
				
				if self.MeleeAI.movementDirectionChangeTimer:IsPastSimMS(self.MeleeAI.movementDirectionChangeDuration) then
					if movementInput == 1 then
						ctrl:SetState(Controller.MOVE_RIGHT, true)
						ctrl:SetState(Controller.MOVE_LEFT, false)
					elseif movementInput == -1 then
						ctrl:SetState(Controller.MOVE_LEFT, true)
						ctrl:SetState(Controller.MOVE_RIGHT, false)
					end
				else
					ctrl:SetState(Controller.MOVE_RIGHT, false)
					ctrl:SetState(Controller.MOVE_LEFT, false)
				end	
			end
			
			-- Look around
			
			-- tryingToBlock implies we have targetWeapon
			ctrl.AnalogAim = tryingToBlock and SceneMan:ShortestDistance(self.Pos, targetWeapon.Pos, SceneMan.SceneWrapsX).Normalized or (dist.Normalized);
		
		end
	end
end

function SyncedUpdate(self)
	if self.SyncedRequestWeaponInfo then
		self.SyncedRequestWeaponInfo = false;
		if self.EquippedItem and self.EquippedItem:IsInGroup("Weapons - Mordhau Melee") then
			self.EquippedItem:SendMessage("Mordhau_AIRequestWeaponInfo");
			-- By now, we should have gotten a reply and set our weapon and info
			if not self.MeleeAI.weapon then
				self.MeleeAI.BasicMode = true;
			else
				if #self.MeleeAI.weaponInfo.validAttackPhaseSets == 0 then
					-- Fallback
					self.MeleeAI.BasicMode = true;
				else
					self.MeleeAI.BasicMode = false;
				end
			end
		end
	end
end
		
		
		
		
		
		
		
		
		
		