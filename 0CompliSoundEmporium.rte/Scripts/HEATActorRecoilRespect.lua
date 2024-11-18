function ThreadedUpdate(self)
	if not self.HEATRecoilRespectInitialized then
		self.HEATController = self:GetController();
		self.HEATRecoilRespectInitialized = true;
		
		self.HEATRecoilRespectBaseAcceptableRecoil = 0.03;
		
		self.HEATRecoilRespectCloseDist = 250;
		self.HEATRecoilRespectMidDist = 450;
		
		self.HEATRecoilRespectResetTimer = Timer();
		self.HEATRecoilRespectResetTime = 100;
	end

	if (not self:IsPlayerControlled()) and self.AI.Target then
	
		--PrimitiveMan:DrawLinePrimitive(self.Head.Pos, self.Head.Pos + Vector(300, 0):RadRotate(self:GetAimAngle(true)), 13);
	
		local posDifference = SceneMan:ShortestDistance(self.Pos,self.AI.Target.Pos,SceneMan.SceneWrapsX)
		local distance = posDifference.Magnitude
		
		local isPointBlank = distance < self.HEATRecoilRespectCloseDist/2
		local isClose = distance < self.HEATRecoilRespectCloseDist
		local isMid = distance < self.HEATRecoilRespectMidDist
		local isFar = distance > self.HEATRecoilRespectMidDist
		
		if (not isPointBlank) and self.EquippedItem and IsHDFirearm(self.EquippedItem) and self.EquippedItem:NumberValueExists("HEAT_Identifier") then
			local currentRecoil = self.EquippedItem:GetNumberValue("HEAT_CurrentRecoil") * self.FlipFactor;
			
			local acceptableRecoil = self.HEATRecoilRespectBaseAcceptableRecoil / (distance / self.HEATRecoilRespectMidDist);
			
			if currentRecoil > acceptableRecoil then
				self.HEATController:SetState(Controller.WEAPON_FIRE, false)
				self.HEATRecoilRespectResetTimer:Reset();
			else
				if not self.HEATRecoilRespectResetTimer:IsPastSimMS(self.HEATRecoilRespectResetTime) then
					--self.HEATController:SetState(Controller.WEAPON_FIRE, false)
				end
			end
		end
	end
end
