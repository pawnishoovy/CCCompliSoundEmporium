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
		-- For now, weapon just stops attacking by itself
	end
end

function Create(self)
	
	self.MeleeAI = {}
	self.MeleeAI.debug = true;
	self.MeleeAI.active = false;

	-- Skill decides how fast the AI attacks, how fast it reacts to attacks, how often it tries to parry.
	-- From 0 to 1.
	self.MeleeAI.skill = self.MeleeAISkill or 0.5;
	
	local activity = ActivityMan:GetActivity();
	if activity then
		self.MeleeAI.skill = (self.MeleeAI.skill / 2) + ((self.MeleeAI.skill / 2) * (activity:GetTeamAISkill(self.Team)/100));
	end
	
	-- Percentage of the time that, after any block, AI will try to parry next time it blocks.
	self.MeleeAI.parryChance = 90 * self.MeleeAI.skill; --%
	-- Whether the next block is going to be attempted as a parry. This means that block will be inputted only when the opponent weapon is actually blockable.
	self.MeleeAI.attemptingParry = math.random(0, 100) < self.MeleeAI.parryChance;
	self.MeleeAI.attemptingParryMaxWaitTimer = Timer();
	self.MeleeAI.attemptingParryMaxWaitTime = 2000;
	
	-- Percentage of the time that, after any block, AI will try to attack rather than continue blocking.
	self.MeleeAI.aggressionAfterBlockChance = 90 * self.MeleeAI.skill; --%
	-- Sometimes, parries just happen without it being intentional by the AI.
	-- This is the chance for it to capitalize on it as opposed to treating it like a normal block.
	self.MeleeAI.aggressionAfterRandomParryChance = 100 * self.MeleeAI.skill; --%
	
	self.MeleeAI.movementInputPrevious = 0;
	self.MeleeAI.movementDirectionChangeTimer = Timer();
	self.MeleeAI.movementDirectionChangeDuration = 100;
	
	-- Our weapon and info about it.
	self.MeleeAI.weapon = nil;
	self.MeleeAI.weaponInfo = {};
	self.MeleeAI.weaponInfo.validAttackPhaseSets = {};
	self.MeleeAI.weaponNextAttackPhaseSetIndex = 1;
	
	-- Parameters to randomize distance held from the opponent. This is a modifier on top of the AIRange of the next attack.
	self.MeleeAI.distanceOffsetMin = -5
	self.MeleeAI.distanceOffsetMax = 5
	self.MeleeAI.distanceOffset = RangeRand(self.MeleeAI.distanceOffsetMin, self.MeleeAI.distanceOffsetMax)
	self.MeleeAI.distanceOffsetDelayTimer = Timer()
	self.MeleeAI.distanceOffsetDelayMin = 700
	self.MeleeAI.distanceOffsetDelayMax = 2200
	self.MeleeAI.distanceOffsetDelay = RangeRand(self.MeleeAI.distanceOffsetDelayMin, self.MeleeAI.distanceOffsetDelayMax)
	
	-- Blocking parameters.
	self.MeleeAI.blocking = false
	self.MeleeAI.blockingDelayMax = 600 * (0.05 + 0.95 * (1 - self.MeleeAI.skill))
	self.MeleeAI.blockingDelay = self.MeleeAI.blockingDelayMax * 0.05
	self.MeleeAI.blockingDelayTimer = Timer()
	
	-- I don't really know how this works. Fil made it. It probably does something.
	self.MeleeAI.attacking = false
	self.MeleeAI.attackOpportunityMissThreshold = 0
	self.MeleeAI.attackOpportunityMissThresholdGain = 15 * (1 - self.MeleeAI.skill)
	self.MeleeAI.attackOpportunityMissDelay = 500
	self.MeleeAI.attackOpportunityMissTimer = Timer()	
	
	-- "Tactic" functions that change behavior. Returns final distance offset and can also do other things every frame.
	self.MeleeAI.tactics = {
		["Hyperoffensive"] = function ()
			self.MeleeAI.controller:SetState(Controller.MOVE_FAST, true);
			return -10;
		end,
		["Offensive"] = function ()
			return math.abs(self.MeleeAI.distanceOffset) - 10;
		end,
		["Defensive"] = function ()
			self.MeleeAI.controller:SetState(Controller.MOVE_FAST, false);
			return self.MeleeAI.distanceOffset -- Basic behaviour
		end,
		["Retreat"] = function ()
			return math.abs(self.MeleeAI.distanceOffset) + (30 * self.MeleeAI.skill); -- Higher skill retreats further and is safer
		end
	}
	
	self.MeleeAI.tactic = "Defensive"
	
end

function ThreadedUpdateAI(self)

	if self.Status >= Actor.DYING or not self.Head then
		return
	end
	
	self.MeleeAI.controller = self:GetController();
	
	-- Misc
	local movementInput = 0
	
	local weapon = self.EquippedItem;
	if weapon and weapon:IsInGroup("Weapons - Mordhau Melee") then
		if (not self.MeleeAI.weapon) or weapon.UniqueID ~= self.MeleeAI.weapon.UniqueID then
			self.SyncedRequestWeaponInfo = true;
			self:RequestSyncedUpdate();
		end
	elseif self.MeleeAI.weapon ~= nil then
		self.MeleeAI.weapon = nil;
		self.MeleeAI.weaponInfo = {};
		self.MeleeAI.weaponInfo.validAttackPhaseSets = {};
		self.MeleeAI.weaponNextAttackPhaseSetIndex = 1;
	end
	
	-- Graphical debug info
	if self.MeleeAI.debug then	
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
		
		pos = pos + Vector(0, 5)
		
		hudBarWidth = 30 * math.max(self.MeleeAI.attackOpportunityMissThreshold / 100, 1 - math.min(self.MeleeAI.attackOpportunityMissTimer.ElapsedSimTimeMS / self.MeleeAI.attackOpportunityMissDelay, 1))
		hudBarColor = 213
		hudBarColorBG = 216
		
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5) + hudBarOffset, pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5) + hudBarOffset, hudBarColorBG)
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * -0.5 + hudBarWidth, hudBarHeight * 0.5), hudBarColor)
		PrimitiveMan:DrawBoxPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorOutline)
	end
	
	-- Actual AI
	local target = self.AI.Target
	if target and (self.MeleeAI.weapon) then
		self.MeleeAI.controller:SetState(Controller.BODY_CROUCH, false);
		self.MeleeAI.controller:SetState(Controller.BODY_PRONE, false);
	
		local dist = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX);
		local distanceToTarget = dist.Magnitude;
		
		if (self.AI.TargetLostTimer.ElapsedSimTimeMS < 5000 and distanceToTarget < 200) or distanceToTarget < 100 then	
			self.MeleeAI.active = true
			
			if self.MeleeAI.debug then
				PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, 13)
				PrimitiveMan:DrawCircleFillPrimitive(target.Pos, 2, 13)
				
				PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + dist, 13);
			end
			
			local nextAttackRange = 50;
			local targetWeapon;
			local targetWeaponMelee;	
			local tryingToBlock;
			
			--- Human enemy behavior
			local didCompatibleBehavior = false;
			if IsAHuman(target) then
				target = ToAHuman(target)
				
				-- We use our own signalling system to do attacks
				self.MeleeAI.controller:SetState(Controller.WEAPON_FIRE, false);
				self.AI.fire = false;
				
				-- Get range of our next attack for later
				local range = self.MeleeAI.weaponInfo.validAttackPhaseSets[self.MeleeAI.weaponNextAttackPhaseSetIndex].AIRange;
				nextAttackRange = range and range or 50;
				
				targetWeapon = target.EquippedItem
				targetWeaponMelee = false
				
				-- See if our target has a MordhauSystem weapon
				if targetWeapon and targetWeapon:IsInGroup("Weapons - Mordhau Melee") then
					targetWeaponMelee = true;
				end	
				
				-- Compatible melee enemy behavior
				if targetWeaponMelee then	
					-- Generally default to regular distance offset
					self.MeleeAI.tactic = "Defensive";
				
					-- Don't do incompatible combat behavior later
					didCompatibleBehavior = true;
					
					local tryingToAttack = self.MeleeAI.weapon:NumberValueExists("Mordhau_AIWeaponCurrentlyBlockable");
				
					local targetIsMeleeAttacking = targetWeapon:NumberValueExists("Mordhau_AIWeaponCurrentlyAttacking");
					local targetMeleeAttackRange;				
					if targetIsMeleeAttacking then
						targetMeleeAttackRange = targetWeapon:GetNumberValue("Mordhau_AIWeaponCurrentRange");
					end
					
					-- Sometimes we want to ignore further blocking and aggress immediately
					local postBlockAggression = false;
					if self.MeleeAI.weapon:NumberValueExists("Mordhau_AIParriedAnAttack") then
						if self.MeleeAI.attemptingParry or math.random(0, 100) < self.MeleeAI.aggressionAfterRandomParryChance then
							postBlockAggression = true;
						end
						self.MeleeAI.weapon:RemoveNumberValue("Mordhau_AIParriedAnAttack");
					elseif self.MeleeAI.weapon:NumberValueExists("Mordhau_AIBlockedAnAttack") then
						if math.random(0, 100) < self.MeleeAI.aggressionAfterBlockChance then
							postBlockAggression = true;
						end
						self.MeleeAI.weapon:RemoveNumberValue("Mordhau_AIBlockedAnAttack");
					end
					
					-- Defend if appropriate
					if (not tryingToAttack) and (targetIsMeleeAttacking) and (distanceToTarget < (targetMeleeAttackRange + 100)) and (not postBlockAggression) then
						tryingToBlock = true;
						-- Always be regularly defensive during blocks
						self.MeleeAI.tactic = "Defensive";
						
						if self.MeleeAI.blockingDelayTimer:IsPastSimMS(self.MeleeAI.blockingDelay) or self.MeleeAI.attemptingParry then
							if self.MeleeAI.attemptingParryMaxWaitTimer:IsPastSimMS(self.MeleeAI.attemptingParryMaxWaitTime) then
								self.MeleeAI.attemptingParry = false;
							end
						
							if (not self.MeleeAI.attemptingParry) or targetWeapon:NumberValueExists("Mordhau_AIWeaponCurrentlyBlockable") then		
								-- Block input
								self.MeleeAI.controller:SetState(Controller.WEAPON_RELOAD, true);
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
								self.MeleeAI.attemptingParryMaxWaitTimer:Reset();
							else
								self.MeleeAI.attemptingParry = false;
							end
						end
					end
					
					-- Try to attack if not blocking, or if we just parried an attack
					if ((not tryingToBlock) and self.MeleeAI.attackOpportunityMissTimer:IsPastSimMS(self.MeleeAI.attackOpportunityMissDelay)) or postBlockAggression then			
						-- Always be offensive during attacks
						self.MeleeAI.tactic = "Offensive";
					
						if RangeRand(0, 100) < self.MeleeAI.attackOpportunityMissThreshold and not postBlockAggression then -- Attack miss Threshold handling
							self.MeleeAI.attackOpportunityMissThreshold = -self.MeleeAI.attackOpportunityMissThresholdGain
							self.MeleeAI.attackOpportunityMissTimer:Reset()
						elseif distanceToTarget < (nextAttackRange) or postBlockAggression then
							self.MeleeAI.attacking = true;
							-- Make sure we don't accidentally block
							self.MeleeAI.controller:SetState(Controller.WEAPON_RELOAD, false);
							self.MeleeAI.weapon:RemoveNumberValue("Mordhau_AIBlockInput");			
								
							-- Initiate our next attack
							local phaseSetName = self.MeleeAI.weaponInfo.validAttackPhaseSets[self.MeleeAI.weaponNextAttackPhaseSetIndex].Name;
							self.MeleeAI.weapon:SetStringValue("Mordhau_AIAttackPhaseSetInput", phaseSetName);
							-- Randomize next attack
							self.MeleeAI.weaponNextAttackPhaseSetIndex = math.floor(math.random(1, #self.MeleeAI.weaponInfo.validAttackPhaseSets));
							
							-- Increase miss Threshold
							self.MeleeAI.attackOpportunityMissThreshold = self.MeleeAI.attackOpportunityMissThreshold + self.MeleeAI.attackOpportunityMissThresholdGain
						end
					end
				end
			end
			
			-- Incompatible, or ranged, enemy behavior
			if not didCompatibleBehavior then
				-- Always be offensive during attacks
				self.MeleeAI.tactic = "Hyperoffensive";
				
				-- Defend if far
				if distanceToTarget >= (nextAttackRange + 20) then
					local enemyCtrl = target:GetController()
					if enemyCtrl then
						local frequency = 800
						if (target.Age % frequency) < frequency * 0.7 and enemyCtrl:IsState(Controller.WEAPON_FIRE) then
							self.MeleeAI.controller:SetState(Controller.WEAPON_RELOAD, true);
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
			
			-- Tactic override for being low on weapon stamina
			 if self.MeleeAI.weapon:GetNumberValue("Mordhau_BlockStaminaPercentage") < 0.2 and not self.MeleeAI.attemptingParry then
				-- Always retreat when in danger
				self.MeleeAI.tactic = "Retreat";
			end		
			
			-- Do distance offset randomization
			if self.MeleeAI.distanceOffsetDelayTimer:IsPastSimMS(self.MeleeAI.distanceOffsetDelay) then
				self.MeleeAI.distanceOffset = RangeRand(self.MeleeAI.distanceOffsetMin, self.MeleeAI.distanceOffsetMax)
				self.MeleeAI.distanceOffsetDelay = RangeRand(self.MeleeAI.distanceOffsetDelayMin, self.MeleeAI.distanceOffsetDelayMax)
				self.MeleeAI.distanceOffsetDelayTimer:Reset()
				
				local tacticList = {}
				for key, tactic in pairs(self.MeleeAI.tactics) do
					table.insert(tacticList, key)
				end	
			end

			-- Apply final tactic function, and get our desired offset too
			local finalOffset = self.MeleeAI.tactics[self.MeleeAI.tactic]()	
			
			-- Movement
			local distanceToKeep = nextAttackRange + finalOffset;
			if math.abs(dist.X) > (distanceToKeep - 7) then
				movementInput = Sign(dist.X);
			elseif math.abs(dist.X) < (distanceToKeep - 5) then
				movementInput = -Sign(dist.X);
			end
			
			if distanceToTarget < 120 then
				self.MeleeAI.controller:SetState(Controller.BODY_JUMP, false)
				self.MeleeAI.controller:SetState(Controller.BODY_JUMPSTART, false)
			end
			
			if movementInput ~= 0 then
				if self.MeleeAI.movementInputPrevious ~= movementInput then
					self.MeleeAI.movementInputPrevious = movementInput
					self.MeleeAI.movementDirectionChangeTimer:Reset()
				end
				
				if self.MeleeAI.movementDirectionChangeTimer:IsPastSimMS(self.MeleeAI.movementDirectionChangeDuration) then
					if movementInput == 1 then
						self.MeleeAI.controller:SetState(Controller.MOVE_RIGHT, true)
						self.MeleeAI.controller:SetState(Controller.MOVE_LEFT, false)
					elseif movementInput == -1 then
						self.MeleeAI.controller:SetState(Controller.MOVE_LEFT, true)
						self.MeleeAI.controller:SetState(Controller.MOVE_RIGHT, false)
					end
				else
					self.MeleeAI.controller:SetState(Controller.MOVE_RIGHT, false)
					self.MeleeAI.controller:SetState(Controller.MOVE_LEFT, false)
				end	
			end
			
			-- Look around
			
			-- tryingToBlock implies we have targetWeapon, look a little above the weapon
			self.MeleeAI.controller.AnalogAim = (tryingToBlock and not self.MeleeAI.weapon:NumberValueExists("Mordhau_AIWeaponCurrentlyAttacking")) and SceneMan:ShortestDistance(self.Head.Pos, (targetWeapon.Pos + Vector(0, -9)), SceneMan.SceneWrapsX).Normalized 
			or (dist.Normalized);
			
			if self.MeleeAI.debug then
				PrimitiveMan:DrawLinePrimitive(self.Head.Pos, self.Head.Pos + self.MeleeAI.controller.AnalogAim * 100, 13);
			end
			
			-- Face our target pls
			if dist.X < 0 then
				self.HFlipped = true;
			else
				self.HFlipped = false;
			end
		end
	end
end

function SyncedUpdate(self)
	if self.SyncedRequestWeaponInfo then
		self.SyncedRequestWeaponInfo = false;
		self.MeleeAI.weaponInfo = {};
		self.MeleeAI.weaponInfo.validAttackPhaseSets = {};
		self.MeleeAI.weaponNextAttackPhaseSetIndex = 1;
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
		
		
		
		
		
		
		
		
		
		