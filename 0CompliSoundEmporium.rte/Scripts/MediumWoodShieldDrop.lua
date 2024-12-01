function Create(self)
	self.CompliSoundWeaponDropSound = CreateSoundContainer("CompliSound Shield Drop Medium Wood Generic", "0CompliSoundEmporium.rte");
end

function OnDetach(self)
	self.CompliSoundDropDone = false;
end

function OnCollideWithTerrain(self)
	if not self.CompliSoundDropDone then
		self.CompliSoundDropDone = true;
		self.CompliSoundWeaponDropSound:Play(self.Pos);
	end
end