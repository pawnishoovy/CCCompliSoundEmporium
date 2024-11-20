function OnDetach(self)

	self:RemoveNumberValue("AI Parry")
	self:RemoveNumberValue("AI Parry Eligible")

	if self.wasThrown == true then
	
		self.throwWounds = 8;
		self.throwPitch = 1;
	
		self.HUDVisible = false;
		
		self:EnableScript("Smallhau.rte/Devices/Shared/Scripts/StraightPierceThrow.lua");
		self.thrownTeam = self.Team;
		
		self.stickMO = nil;
		self.stickVecX = 0;
		self.stickVecY = 0;
		self.stickRot = 0;
		self.stickDeepness = RangeRand(0.1, 1);

		self.stuck = false;
		
		self.phase = 0;
	end

	self:DisableScript("Smallhau.rte/Devices/Weapons/Melee/Longsword/Longsword.lua");
	
	self:RemoveStringValue("Parrying Type");
	self.Parrying = false;
	
	self.Blocking = false;
	self:RemoveNumberValue("Blocking");
	
	self.currentAttackAnimation = 0;
	self.currentAttackSequence = 0;
	self.currentAttackStart = false
	self.attackAnimationIsPlaying = false
	
	self.rotationInterpolationSpeed = 25;
	
	self.Frame = 5;
	
	self.canBlock = false;
	
end

function OnAttach(self)

	self.HUDVisible = true;

	self:DisableScript("Smallhau.rte/Devices/Shared/Scripts/StraightPierceThrow.lua");
	self.PinStrength = 0;

	self:EnableScript("Smallhau.rte/Devices/Weapons/Melee/Longsword/Longsword.lua");
	
	if self.offTheGround ~= true then --equipped from inv
	
		self.equipAnim = true;
		
		-- local rotationTarget = -225 / 180 * math.pi
		-- local stanceTarget = Vector(-4, 0);
	
		-- self.stance = self.stance + stanceTarget
		
		-- rotationTarget = rotationTarget * self.FlipFactor
		-- self.rotation = self.rotation + rotationTarget
		
		-- self.StanceOffset = self.originalStanceOffset + self.stance
		-- self.RotAngle = self.RotAngle + self.rotation
		
	end
	
	self.canBlock = true;
	
end

function Update(self)

	if not self:IsAttached() then
		self.offTheGround = true;
	else
		self.offTheGround = false;
	end
	
	if self.canBlock == false then
		if self.WoundCount > self.woundCounter then
			self.woundCounter = self.WoundCount;
			self.breakSound:Play(self.Pos);
		end
	end
	
end