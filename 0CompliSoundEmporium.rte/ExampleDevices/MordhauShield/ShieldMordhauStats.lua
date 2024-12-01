function Create(self)

	-----------------
	----------------- Mordhau shield system stats file
	-----------------
	
	-- Welcome to the Mordhau shield system.
	
	-- This is much simpler than the Mordhau System, so just read the comments and set things appropriately.
	
	-----------------
	----------------- Stats
	-----------------
	
	-- Whether to enable blocking animation. If true, will apply BlockingStanceOffset and BlockingRotationTarget and also visibly react to blocking attacks.
	self.BlockingAnimation = true;	
	-- Relative to original .ini-defined StanceOffset.
	self.BlockingStanceOffset = Vector(8, -8);
	-- Rotation target when idle.
	self.IdleRotationTarget = 5;
	-- Rotation target when blocking.
	self.BlockingRotationTarget = 25;
	-- AngVel to apply when blocking an attack, whether actively blocking or not (but BlockingAnimation has to be enabled)
	self.BlockAngVel = 5;
	-- Multiplier for incoming wounds' efficacy when a main-hand weapon is in a phase with either blocksAttacks or parriesAttacks.
	self.BlockingDamageMultiplier = 0.5;
	-- Whether this shield also acts as if it parries incoming attacks when a main-hand weapon is in a phase that parriesAttacks.
	self.ParriesWithWeapon = true;
	-- Sound to play when a successful parry occurs. Safe to nil.
	self.ParrySound = CreateSoundContainer("Parry CompliSound Mordhau Shield", "0CompliSoundEmporium.rte");
	-- Whether this shield negates all flinching even if hit out of block, allowing attacking and defending at the same time.
	self.Hyperarmor = true;
	
	-- Real intended gib wound limit. GibWoundLimit manipulation can throw things out of whack, so we need this here.
	-- Note that the actual GibWoundLimit set is 999 so your shield is not nigh-invincible unless you set it yourself later.
	self.RealGibWoundLimit = 25;

end