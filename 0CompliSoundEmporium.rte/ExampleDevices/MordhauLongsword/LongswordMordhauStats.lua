function Create(self)

	-----------------
	----------------- Mordhau system stats file
	-----------------
	
	-- attackType convention:
	
	-- Slash (referring to motion, not necessarily sharp strikes)
	-- Stab (referring to motion, not necessarily piercing strikes)

	-----------------
	----------------- General
	-----------------	
	
	-- Whether to enable debug draws and console logs or not.
	self.DebugInfo = true;
	
	-- Rotation speed when not playing any PhaseSets and merely idling.
	-- 1 is perfect snapping, so use a smaller value.
	self.IdleRotationSpeed = 0.2;

	-- Rotation target when not playing any PhaseSets and merely idling.
	self.IdleRotation = -20;

	-- Easing functions. They have to be here so they're defined by the time you use them in reload phases.
	self.EaseLinear = function (x)
		return x;
	end
	self.EaseOutCubic = function (x)
		return 1 - math.pow(1 - x, 3);
	end
	self.EaseInOutCubic = function (x)
		return x < 0.5 and 4 * x * x * x or 1 - math.pow(-2 * x + 2, 3) / 2;
	end
	self.EaseInCirc = function (x)
		return 1 - math.sqrt(1 - math.pow(x, 2));
	end
	
	-----------------
	----------------- Melee
	-----------------
	
	-- Lockout in MS from doing anything but block input after being flinched by being hit by melee.
	self.FlinchCooldown = 300;	
	
	-- Lockout in MS from doing anything but block input after being parried, after Parried Reaction.
	self.ParryCooldown = 300;
	
	-----------------
	----------------- Sounds and FX
	-----------------
	
	-- The below is all recommended defaults. What you will likely want to do is change the sounds, and optionally the GFX.
	-- Nilling anything here is safe and the GFX/SFX simply won't happen if it's non-existent.
	
	-- This function is predefined in MordhauSystem and runs when hitting a target to decide which GFX and sounds are appropriate.
	-- It has the signature (self, hitTargetMO, absoluteHitPos) and does both the detecting and the spawning/playing.
	-- You can override it here and do your own thing if you want.
	self.HitMOFunction = nil;
	
	self.HitGFX = {};
	
	self.HitGFX.Default = CreateMOSRotating("CompliSound Mordhau Terrain Soft Effect", "0CompliSoundEmporium.rte");
	self.HitGFX.Concrete = CreateMOSRotating("CompliSound Mordhau Terrain Hard Effect", "0CompliSoundEmporium.rte");
	self.HitGFX.Dirt = CreateMOSRotating("CompliSound Mordhau Terrain Soft Effect", "0CompliSoundEmporium.rte");
	self.HitGFX.Sand = CreateMOSRotating("CompliSound Mordhau Terrain Soft Effect", "0CompliSoundEmporium.rte");
	self.HitGFX.SolidMetal = CreateMOSRotating("CompliSound Mordhau Terrain Hard Effect", "0CompliSoundEmporium.rte");	
	self.HitGFX.Flesh = CreateMOSRotating("CompliSound Mordhau Flesh Effect", "0CompliSoundEmporium.rte");
	self.HitGFX.Metal = CreateMOSRotating("CompliSound Mordhau Terrain Hard Effect", "0CompliSoundEmporium.rte");
	
	self.HitSFX = {};
	self.HitSFX.Default = CreateSoundContainer("CompliSound Mordhau Terrain Hit Concrete", "0CompliSoundEmporium.rte");
	self.HitSFX.SlashFlesh = CreateSoundContainer("Slash Flesh CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.HitSFX.SlashMetal = CreateSoundContainer("Slash Metal CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.HitSFX.StabFlesh = CreateSoundContainer("Stab Flesh CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.HitSFX.StabMetal = CreateSoundContainer("Stab Metal CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.HitSFX.Concrete = CreateSoundContainer("CompliSound Mordhau Terrain Hit Concrete", "0CompliSoundEmporium.rte");
	self.HitSFX.Dirt = CreateSoundContainer("CompliSound Mordhau Terrain Hit Dirt", "0CompliSoundEmporium.rte");
	self.HitSFX.Sand = CreateSoundContainer("CompliSound Mordhau Terrain Hit Sand", "0CompliSoundEmporium.rte");
	self.HitSFX.SolidMetal = CreateSoundContainer("CompliSound Mordhau Terrain Hit SolidMetal", "0CompliSoundEmporium.rte");
	self.HitSFX.BeingBlocked = CreateSoundContainer("Being Blocked CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	
	-- Same as HitFunction. Happens on the OnMessage received when querying for being blocked, by default just handles playing BeingBlocked.
	self.BeingBlockedFunction = nil;
	
	self.BlockGFX = {};
	self.BlockGFX.BlockSlash = CreateMOSRotating("CompliSound Mordhau Block Slash Effect", "0CompliSoundEmporium.rte");
	self.BlockGFX.BlockStab = CreateMOSRotating("CompliSound Mordhau Block Stab Effect", "0CompliSoundEmporium.rte");
	self.BlockGFX.Parry = CreateMOSRotating("CompliSound Mordhau Parry Effect", "0CompliSoundEmporium.rte");
	self.BlockGFX.HeavyBlock = CreateMOSRotating("CompliSound Mordhau Heavy Block Effect", "0CompliSoundEmporium.rte");
	
	self.BlockSFX = {};
	self.BlockSFX.BlockSlash = CreateSoundContainer("Block Slash CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.BlockSFX.BlockStab = CreateSoundContainer("Block Stab CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.BlockSFX.ParryAdd = CreateSoundContainer("Parry Add CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	self.BlockSFX.HeavyBlockAdd = CreateSoundContainer("Heavy Block Add CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");

	-----------------
	----------------- Regular inputtable PhaseSets
	-----------------	
	
	-- PhaseSet to trigger when block is inputted (reload button)
	-- A sane block should include a canBeHeld phase that blocksAttacks, but this is not required. You can do whatever
	-- you like, including making a block that only parries for a short period of time before returning.
	-- Please note that due to current input limitations, canBeHeld can only be triggered by the three inputs below,
	-- and reload cannot currently be held to hold block.
	self.BlockInputPhaseSetName = "Block PhaseSet";
	
	-- PhaseSet to trigger when regular weapon fire is inputted
	self.PrimaryInputPhaseSetName = "Stab PhaseSet";
	-- PhaseSet to trigger when primary hotkey is inputted
	self.PrimaryHotkeyInputPhaseSetName = "Slash PhaseSet";
	-- PhaseSet to trigger when auxiliary hotkey is inputted
	self.AuxiliaryHotkeyInputPhaseSetName = "Slash PhaseSet";
	
	-- PhaseSet to trigger when an actor equips this from inventory.
	-- Doesn't trigger when being picked up from the ground.
	self.EquipPhaseSetName = "Equip PhaseSet";
	
	-----------------
	----------------- PhaseSets
	-----------------	

	-- A "PhaseSet" is a full animation that plays out. It can do a lot of things - attack, be blocked, block attacks, etc.
	self.PhaseSets = {};
	
	------------------------------------------------------------------------------
	---------------------------------PHASESET-------------------------------------
	------------------------------------------------------------------------------
	
	-- Create and place a PhaseSet into our list of PhaseSets
	local phaseSetIndex = 1;
	local phaseSet = {};
	
	-- Name of the PhaseSet, used to play it.
	phaseSet.Name = "Slash PhaseSet";
	-- Whether this PhaseSet can be combod into if played during another PhaseSet.
	-- False here will basically ignore input into it if anything except idle.
	phaseSet.canBeCombodInto = true;
	-- Whether this is a dedicated blocking PhaseSet or not. This should not be set true for anything
	-- that happens to have a phase that can block attacks, but the one you'll mainly be using to block
	-- (like the one on your block input)
	phaseSet.isBlockingPhaseSet = false;
	phaseSet.Phases = {};
	
	self.PhaseSets[phaseSetIndex] = phaseSet;
	
	----------------------------------PHASE---------------------------------------
	
	-- Create and place a Phase into our PhaseSet
	local phaseIndex = 1;
	local Phase = {};
	
	-- Name for organization purposes only.
	Phase.Name = "Slash Prepare";
	-- Full duration of this Phase in MS.
	Phase.Duration = 300;
	
	-- Whether this phase will parry attacks that hit it.
	Phase.parriesAttacks = false;
	-- Whether this phase will block attacks that hit it.
	Phase.blocksAttacks = false;
	-- Whether this phase can be held by holding down its input, preventing progress until the input is released.
	-- A held phase that does damage will act as normal (not doing damage more than once to the same target, following cleaving rules etc.).
	-- Completely overriden for block PhaseSets.
	Phase.canBeHeld = true;
	-- Whether this phase allows for cancelling the PhaseSet entirely to go directly into blocking.
	Phase.canBeBlockCancelled = true;
	-- Whether playing a new PhaseSet during this phase will buffer it for later playing during a phase that is canComboOut == true.
	-- Note that any phase with this false will clear any previous buffer, and allowing buffers but never having a canComboOut will make it irrelevant.
	Phase.allowsPhaseSetBuffering = false;
	-- Whether trying to play a new PhaseSet during this phase, whether manually or by buffered input, will combo into it or not.
	-- Recommended to use only on the 'recovery' stages of your PhaseSet so it has a chance to play out even with spammed inputs.
	Phase.canComboOut = false;
	
	-- Whether this Phase should check for being blocked by blocking melee along its ray vector or not.
	-- You can check for this separately from checking to damage MOs, for example to let yourself be blocked early
	-- for potentially more consistent results.
	Phase.canBeBlocked = false;
	-- Whether this Phase should check for MOs to hit and damage along its ray vector or not.
	-- Can be done separately from checking to be blocked, for example to make unblockable attacks.
	Phase.doesDamage = false;
	-- The Type of attack this phase is. You can put anything you want here to suit your purposes, but you should stick to the convention
	-- outlined near the top of this script to ensure best compatibility.
	Phase.attackType = "None";
	-- If Cleaves is on, then this phase will do damage to every MO it meets (aside from things it has already struck, accounting for parents),
	-- allowing it to hit bunched-up objects. If it's false, this phase will only do damage to the first MO it meets.
	Phase.Cleaves = false;
	-- Whether this phase can be stopped from damaging further after hitting terrain. Cleaves == true resets this interruption after at least a phase,
	-- but if it's false then one interruption will nullify the entire PhaseSet.
	Phase.isInterruptableByTerrain = false;
	-- Wounds to cause when hitting an MO. Decimals will result in randomly doing one more wound sometimes, depending on how much extra there is.
	Phase.Damage = 0.0;
	-- Acts as expected, per-wound.
	Phase.woundDamageMultiplier = 0.0;
	-- Whether to dismember parts of Actors instead of gibbing them, if dealing enough damage to gib.
	Phase.dismemberInsteadOfGibbing = false;
	-- The first position in a line of rays to cast, relative to SpriteOffset. Does nothing without canBeBlocked or doesDamage.
	-- Place this and rayVecSecondPos "along the blade", so to speak.
	Phase.rayVecFirstPos = Vector(0, 0);
	-- The second position in a line of rays to cast, relative to SpriteOffset. Does nothing without canBeBlocked or doesDamage.
	Phase.rayVecSecondPos = Vector(0, 0);
	-- How many rays to cast along the line made by the two positions above. 
	Phase.rayDensity = 0;
	-- Ray length, in pixels.
	Phase.rayRange = 0;
	-- Multiplier for the above range when detecting terrain. Put this around 0.5 for more forgiving rays.
	Phase.rayTerrainRangeMultiplier = 0;
	-- What angle to cast the ray, in degrees, relative to weapon orientation. 0 is straight to the right.
	Phase.rayAngle = 0;
	
	-- Starting frame.
	Phase.frameStart = 0;
	-- Ending frame.
	Phase.frameEnd = 1;
	-- Easing function to use for frame animation. You could define your own here if you really wanted.
	Phase.frameEasingFunc = self.EaseLinear;
	
	-- Speed at which all rotation happens during this phase.
	-- 1 is perfect adherence (theoretically), anything less will potentially not reach within the frame.
	Phase.rotationSpeed = 0.4;
	-- Starting angle, in degrees. Discrepancies between any two phase's start and end angles will not results
	-- in snapping, but you probably still want to line them up.
	Phase.angleStart = -25;
	-- Ending angle.
	Phase.angleEnd = 100;
	-- Easing function to use for angle animation. You could define your own here if you really wanted.
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	-- Speed at which all stance shifting happens during this phase.
	-- 1 is perfect adherence (theoretically), anything less will potentially not reach within the frame.
	Phase.stanceOffsetSpeed = 1;	
	-- Starting relative StanceOffset offset, based off of original .ini defined one.
	Phase.stanceOffsetStart = Vector(0, 0);
	-- Ending relative StanceOffset offset, based off of original .ini defined one.
	Phase.stanceOffsetEnd = Vector(-6, -20);
	-- Easing function to use for stance animation. You could define your own here if you really wanted.
	Phase.stanceEasingFunc = self.EaseLinear;
	
	-- Speed at which JointOffset moves along.
	-- 1 is perfect adherence (theoretically), anything less will potentially not reach within the frame.
	Phase.jointOffsetSpeed = 1;
	-- Absolute JointOffset.
	Phase.jointOffset = Vector(0, 10);
	-- Speed at which SupportOffset moves along.
	-- 1 is perfect adherence (theoretically), anything less will potentially not reach within the frame.
	Phase.supportOffsetSpeed = 1;
	-- Absolute SupportOffset.
	Phase.supportOffset = Vector(-1, 14);
	
	-- SoundContainer to play when this Phase starts. Will overlap with previous phase's soundEnd.
	Phase.soundStart = nil;
	-- SoundContainer to play when this Phase ends. Will overlap with next phase's soundStart.
	Phase.soundEnd = nil;
	
	-- Callback after this phase is entered and all default values are set.
	Phase.enterPhaseCallback = function (self)
		
	end
	-- Callback done every frame of this phase, after value setting and collision logic but before finish-specific behavior.
	Phase.constantCallback = function (self)
		
	end
	-- Callback just before exiting the phase and deleting current phase data.
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Slash Attack";
	Phase.Duration = 300;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = false;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = false;
	
	Phase.canBeBlocked = true;
	Phase.doesDamage = true;
	Phase.attackType = "Slash";
	Phase.isInterruptableByTerrain = true;
	Phase.Cleaves = false;
	Phase.Damage = 4.0;
	Phase.woundDamageMultiplier = 2.0;
	Phase.dismemberInsteadOfGibbing = true;
	Phase.rayVecFirstPos = Vector(0, 7);
	Phase.rayVecSecondPos = Vector(0, -20);
	Phase.rayDensity = 14;
	Phase.rayRange = 7;
	Phase.rayTerrainRangeMultiplier = 0.5;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 1;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseLinear;
	
	Phase.rotationSpeed = 0.8;	
	Phase.angleStart = 100;
	Phase.angleEnd = -110;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(-6, -20);
	Phase.stanceOffsetEnd = Vector(6, 20);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = CreateSoundContainer("Slash Whoosh CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Slash Recover";
	Phase.Duration = 450;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = false;
	Phase.canComboOut = true;
	
	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 0;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseLinear;
	
	Phase.rotationSpeed = 0.3;	
	Phase.angleStart = -110;
	Phase.angleEnd = -25;
	Phase.angleEasingFunc = self.EaseLinear;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(-6, 20);
	Phase.stanceOffsetEnd = Vector(0, 0);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	------------------------------------------------------------------------------
	---------------------------------PHASESET-------------------------------------
	------------------------------------------------------------------------------
	
	local phaseSetIndex = phaseSetIndex + 1;
	local phaseSet = {};
	
	phaseSet.Name = "Stab PhaseSet";
	phaseSet.canBeCombodInto = true;
	phaseSet.isBlockingPhaseSet = false;
	phaseSet.Phases = {};
	
	self.PhaseSets[phaseSetIndex] = phaseSet;
	
	----------------------------------PHASE---------------------------------------
	
	local phaseIndex = 1;
	local Phase = {};
	
	Phase.Name = "Stab Prepare";
	Phase.Duration = 400;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = true;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = false;
	Phase.canComboOut = false;

	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 0;
	Phase.frameEnd = 1;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.8;
	Phase.angleStart = -25;
	Phase.angleEnd = -90;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(0, 0);
	Phase.stanceOffsetEnd = Vector(-20, -15);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 5);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	local phaseIndex = phaseIndex + 1;
	local Phase = {};
	
	Phase.Name = "Stab Attack";
	Phase.Duration = 300;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = false;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = false;

	Phase.canBeBlocked = true;
	Phase.doesDamage = true;
	Phase.attackType = "Stab";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = true;
	Phase.Damage = 2.0;
	Phase.woundDamageMultiplier = 3.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(-1, 0);
	Phase.rayVecSecondPos = Vector(1, 0);
	Phase.rayDensity = 3;
	Phase.rayRange = 17;
	Phase.rayTerrainRangeMultiplier = 1.0
	Phase.rayAngle = 90;
	
	Phase.frameStart = 1;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.8;
	Phase.angleStart = -100;
	Phase.angleEnd = -85;
	Phase.angleEasingFunc = self.EaseLinear;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(-20, -15);
	Phase.stanceOffsetEnd = Vector(10, -13);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 5);
	
	Phase.soundStart = CreateSoundContainer("Stab Whoosh CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Stab Rebound";
	Phase.Duration = 400;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = true;
	
	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 0;
	Phase.frameEnd = 6;
	Phase.frameEasingFunc = self.EaseLinear;
	
	Phase.rotationSpeed = 0.6;	
	Phase.angleStart = -100;
	Phase.angleEnd = 0;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(10, -13);
	Phase.stanceOffsetEnd = Vector(-5, -7);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 10);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Stab Recover";
	Phase.Duration = 500;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = true;
	
	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(-5, 2);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 4;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 6;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseLinear;
	
	Phase.rotationSpeed = 0.6;	
	Phase.angleStart = 0;
	Phase.angleEnd = -25;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 0.1;	
	Phase.stanceOffsetStart = Vector(10, 2);
	Phase.stanceOffsetEnd = Vector(0, 0);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	
	------------------------------------------------------------------------------
	---------------------------------PHASESET-------------------------------------
	------------------------------------------------------------------------------
	
	local phaseSetIndex = phaseSetIndex + 1;
	local phaseSet = {};
	
	phaseSet.Name = "Block PhaseSet";
	phaseSet.canBeCombodInto = true;
	phaseSet.isBlockingPhaseSet = true;
	phaseSet.Phases = {};
	
	self.PhaseSets[phaseSetIndex] = phaseSet;
	
	----------------------------------PHASE---------------------------------------
	
	local phaseIndex = 1;
	local Phase = {};
	
	Phase.Name = "Block Parry";
	Phase.Duration = 200;
	
	Phase.parriesAttacks = true;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = false;
	Phase.allowsPhaseSetBuffering = false;
	Phase.canComboOut = false;

	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 0;
	Phase.frameEnd = 3;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.4;
	Phase.angleStart = -25;
	Phase.angleEnd = -45;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(0, 0);
	Phase.stanceOffsetEnd = Vector(-1, -20);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(2, 14);
	
	Phase.soundStart = CreateSoundContainer("Stab Whoosh CompliSound Mordhau Longsword", "0CompliSoundEmporium.rte");
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Block Hold";
	Phase.Duration = 150;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = true;
	Phase.canBeHeld = true;
	Phase.canBeBlockCancelled = false;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = true;
	
	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 3;
	Phase.frameEnd = 2;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.6;	
	Phase.angleStart = -45;
	Phase.angleEnd = -140;
	Phase.angleEasingFunc = self.EaseLinear;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(-1, -20);
	Phase.stanceOffsetEnd = Vector(3, -20);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(2, 0);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Block Return 1";
	Phase.Duration = 150;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = false;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = true;
	
	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 2;
	Phase.frameEnd = 2;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.2;	
	Phase.angleStart = -140;
	Phase.angleEnd = -50;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 0.75;	
	Phase.stanceOffsetStart = Vector(3, -20);
	Phase.stanceOffsetEnd = Vector(0, -10);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	phaseIndex = phaseIndex + 1;
	Phase = {};
	
	Phase.Name = "Block Return 2";
	Phase.Duration = 150;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = true;
	Phase.canComboOut = false;
	
	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 2;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.2;	
	Phase.angleStart = -50;
	Phase.angleEnd = -20;
	Phase.angleEasingFunc = self.EaseInOutCubic;
	
	Phase.stanceOffsetSpeed = 0.75;	
	Phase.stanceOffsetStart = Vector(0, -10);
	Phase.stanceOffsetEnd = Vector(0, 0);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	------------------------------------------------------------------------------
	---------------------------------PHASESET-------------------------------------
	------------------------------------------------------------------------------
	
	local phaseSetIndex = phaseSetIndex + 1;
	local phaseSet = {};
	
	phaseSet.Name = "Parried Reaction PhaseSet";
	phaseSet.canBeCombodInto = true;
	phaseSet.isBlockingPhaseSet = false;
	phaseSet.Phases = {};
	
	self.PhaseSets[phaseSetIndex] = phaseSet;
	
	----------------------------------PHASE---------------------------------------
	
	local phaseIndex = 1;
	local Phase = {};
	
	Phase.Name = "Reaction";
	Phase.Duration = 200;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = false;
	Phase.canComboOut = false;

	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 0;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.6;
	Phase.angleStart = 90;
	Phase.angleEnd = 80;
	Phase.angleEasingFunc = self.EaseLinear;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(0, 0);
	Phase.stanceOffsetEnd = Vector(-6, -20);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;
	
	----------------------------------PHASE---------------------------------------
	
	local phaseIndex = phaseIndex + 1;
	local Phase = {};
	
	Phase.Name = "Reaction Recover";
	Phase.Duration = 300;
	
	Phase.parriesAttacks = false;
	Phase.blocksAttacks = false;
	Phase.canBeHeld = false;
	Phase.canBeBlockCancelled = true;
	Phase.allowsPhaseSetBuffering = false;
	Phase.canComboOut = false;

	Phase.canBeBlocked = false;
	Phase.doesDamage = false;
	Phase.attackType = "None";
	Phase.Cleaves = false;
	Phase.isInterruptableByTerrain = false;
	Phase.Damage = 0.0;
	Phase.woundDamageMultiplier = 0.0;
	Phase.dismemberInsteadOfGibbing = false;
	Phase.rayVecFirstPos = Vector(0, 0);
	Phase.rayVecSecondPos = Vector(0, 0);
	Phase.rayDensity = 0;
	Phase.rayRange = 0;
	Phase.rayTerrainRangeMultiplier = 0;
	Phase.rayAngle = 0;
	
	Phase.frameStart = 0;
	Phase.frameEnd = 0;
	Phase.frameEasingFunc = self.EaseInOutCubic;
	
	Phase.rotationSpeed = 0.4;
	Phase.angleStart = 80;
	Phase.angleEnd = -25;
	Phase.angleEasingFunc = self.EaseLinear;
	
	Phase.stanceOffsetSpeed = 1;	
	Phase.stanceOffsetStart = Vector(-6, -20);
	Phase.stanceOffsetEnd = Vector(-0, 0);
	Phase.stanceEasingFunc = self.EaseLinear;
	
	Phase.jointOffsetSpeed = 1;
	Phase.jointOffset = Vector(0, 10);
	Phase.supportOffsetSpeed = 1;
	Phase.supportOffset = Vector(-1, 14);
	
	Phase.soundStart = nil;
	Phase.soundEnd = nil;
	
	Phase.enterPhaseCallback = function (self)
		
	end
	Phase.constantCallback = function (self)
		
	end
	Phase.exitPhaseCallback = function (self)
		
	end
	
	self.PhaseSets[phaseSetIndex].Phases[phaseIndex] = Phase;

end