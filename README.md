
# CCCompliSoundEmporium

Welcome to the CompliSound Emporium, by trulythepawn.

This is a huge set of sounds, generic spawnable VFX, and generic scripts for usage in other mods, with a focus on terrain-specific effects for things like footsteps, bullets hitting various terrains, etcetera.


## About sounds:

I recommend using the files in this mod directly by pathing to them inside of your own mod. FMOD intelligently re-uses sound files, which means that it is safe for you to path to them even if this .rte also does. It won't use more memory needlessly.

However, presets are provided and the mod is prioritized to the loaded first alphabetically, making it possible for you to use them anyway if you really don't want to make your own presets.


## About VFX:

It's theoretically inadvisable to use the presets in this mod directly in .ini, because ideally every CC mod is self-contained due to the potentially wonky alphabetic loading (what if your mod starts with 00?) but this is the only available way to use these effects outside of Lua.

However: using these presets in scripts specifically is safe. Lua scripts only ever run after all loading is done, which means it doesn't matter when this mod was loaded versus your own.


## About scripts:

Pathing to the scripts directly is fine and simple. If you find they don't work as expected, check inside the script itself for any relevant instructions.
