function Create(self)
	-- Uses MordhauShieldSystem wound count to do some visual FX.
	
	self.damageSound = CreateSoundContainer("Damage CompliSound Mordhau Shield", "0CompliSoundEmporium.rte");
end

function ThreadedUpdate(self)
	self.damageSound.Pos = self.Pos;
	if self.EffectiveWoundCount then
		if self.EffectiveWoundCount > self.RealGibWoundLimit * 0.66 then
			if self.Frame ~= 2 then
				self.Frame = 2;
				self.damageSound:Play(self.Pos);
			end
		elseif self.EffectiveWoundCount > self.RealGibWoundLimit * 0.33 then
			if self.Frame ~= 1 then
				self.Frame = 1;
				self.damageSound:Play(self.Pos);
			end
		end
	end
end