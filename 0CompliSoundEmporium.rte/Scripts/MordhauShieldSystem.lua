function OnMessage(self, message, object)
	if message == "Mordhau_ParryingShieldHit" then
		if self.ParrySound then
			self.ParrySound:Play(self.Pos);
		end
	end
end

function Create(self)
	
	-- Set this so attacking weapons know not to flinch ever
	if self.Hyperarmor then
		self:SetNumberValue("Mordhau_ShieldHyperarmor", 1);
	end
	
	self.EffectiveWoundCount = self:NumberValueExists("Mordhau_EffectiveWoundCount") and self:GetNumberValue("Mordhau_EffectiveWoundCount") or self.WoundCount;
	self:RemoveNumberValue("Mordhau_EffectiveWoundCount");
	
	-- We use EffectiveWoundCount and the stats-defined RealGibWoundLimit instead.
	self.GibWoundLimit = 999;
	
	self.LastWoundCount = self.WoundCount;
	
	-----------------
	----------------- Animation
	-----------------
	
	-- Temporary stance offsets. Reset every frame.
	self.HorizontalAnim = 0;
	self.VerticalAnim = 0;

	self.OriginalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	
	-- Rotational input into the animation system. Resets every frame, has nothing to do with vanilla AngularVel.
	self.AngVel = 0;
	
	self.RotationSpeed = 10;
	self.RotationTarget = 0;
	self.Rotation = 0;
	
	-- Manual modifier for RotationTarget for custom use, not reset ever.
	self.RotationTargetManualAddition = 0;	
	
	-- Neater to have a separate variable for our original-relative stance setting.
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
	if self.ParrySound then
		self.ParrySound.Pos = self.Pos;
	end

	self:RemoveNumberValue("Mordhau_ShieldCurrentlyParrying");
	
	self.AngVel = 0;
	self.HorizontalAnim = 0;
	self.VerticalAnim = 0;
	
	if self.DoBlockAnim then
		self.DoBlockAnim = false;
		self.AngVel = self.BlockAngVel;
		self.HorizontalAnim = -4;
	end

	-- Should not be required, but sometimes gibbing crashes due to this somehow..
	if not MovableMan:ValidMO(self.Parent) then
		self.Parent = nil;
	end

	local addWoundsNormally = true;
	
	if self.Parent then
		local isPlayerControlled = self.Parent:IsPlayerControlled();
	
		-- TODO: fix this mess
		local reloadInput;
		local heldReloadInput;
		reloadInput = self.ParentController:IsState(Controller.WEAPON_RELOAD) 
		heldReloadInput = isPlayerControlled and UInputMan:KeyHeld(Key.R);
		reloadInput = heldReloadInput and heldReloadInput or reloadInput;
	
		self.RotationTarget = self.IdleRotationTarget;
		self.StanceOffsetTarget = Vector(0, 0);
		
		local parentMelee;
		if self.Parent.EquippedItem and self.Parent.EquippedItem:IsInGroup("Weapons - Mordhau Melee") then
			parentMelee = self.Parent.EquippedItem;
			-- Blocking melee weapon can make us act as if we're blocking, just in case
			reloadInput = parentMelee:NumberValueExists("Mordhau_CurrentlyBlockingOrParrying") and true or reloadInput;
		end
		
		-- Blocking behavior
		if reloadInput then	
			-- Multiplied effective wounds when blocking
			addWoundsNormally = false;
			if self.WoundCount > self.LastWoundCount then
				self.EffectiveWoundCount = self.EffectiveWoundCount + ((self.WoundCount - self.LastWoundCount) * self.BlockingDamageMultiplier);
				if self.BlockingAnimation then
					self.DoBlockAnim = true;
				end
			end				
		
			-- Blocking animation
			if self.BlockingAnimation then
				self.StanceOffsetTarget = self.BlockingStanceOffset;
				
				self.RotationTarget = self.BlockingRotationTarget;
			end
			
			if self.ParriesWithWeapon and parentMelee and parentMelee:NumberValueExists("Mordhau_CurrentlyParrying") then
				-- Let incoming weapons know to damage us then bounce as if parried
				self:SetNumberValue("Mordhau_ShieldCurrentlyParrying", 1);
			end
		end
		
		-- Animation
		-- Rotation, absolute
		self.RotationTarget = self.RotationTargetOverride or self.RotationTarget;
		self.RotationTarget = self.RotationTarget - (self.AngVel * 4) + self.RotationTargetManualAddition;
		
		self.Rotation = self.Rotation + ((self.RotationTarget - self.Rotation) * math.min(1, TimerMan.DeltaTimeSecs * self.RotationSpeed))
		
		local total = math.rad(self.Rotation) * self.FlipFactor;
		self.InheritedRotAngleOffset = total * self.FlipFactor;
		
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
	end
	
	if addWoundsNormally then
		if self.WoundCount > self.LastWoundCount then
			self.EffectiveWoundCount = self.EffectiveWoundCount + (self.WoundCount - self.LastWoundCount);
		end
	end
	
	self.LastWoundCount = self.WoundCount;
	
	if self.EffectiveWoundCount >= self.RealGibWoundLimit then
		self:GibThis();
	end
end

function OnSave(self)
	self:SetNumberValue("Mordhau_EffectiveWoundCount", self.EffectiveWoundCount);
end