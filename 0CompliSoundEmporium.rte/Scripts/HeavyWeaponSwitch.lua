function Create(self)
	self.CompliSoundWeaponSwitchSound = CreateSoundContainer("CompliSound Weapon Switch Heavy", "0CompliSoundEmporium.rte");
end

function OnAttach(self)
	self.CompliSoundWeaponSwitchSound:Play(self.Pos);
end

function ThreadedUpdate(self)
	self.CompliSoundWeaponSwitchSound.Pos = self.Pos;
end