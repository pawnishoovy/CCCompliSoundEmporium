
# CCCompliSoundEmporium

Welcome to the CompliSound Emporium, by trulythepawn.
Compatible with CCCP Release 7.0.

This is a huge set of sounds, generic spawnable VFX, and generic scripts for usage in other mods, with a focus on terrain-specific effects for things like footsteps, bullets hitting various terrains, etcetera.

It also includes the HEATSystem, which handles staged, animated reloads, visual recoil, among other things, as well as the MordhauSystem, which is a melee weapon framework that makes it easy to animate interesting attacks with fully-featured blocking and parrying mechanics.

Both have example devices so you can see a practical implementation of each.


## About sounds:

Many of the sounds are tied to scripts you can use directly to avoid .ini entirely. However, if you must use a sound in .ini, I recommend using the files in this mod directly by pathing to them inside of your own mod. FMOD intelligently re-uses sound files, which means that it is safe for you to path to them even if this .rte also does. It won't use more memory needlessly.

However, presets are provided and the mod is prioritized to be loaded first alphabetically, making it possible for you to use them anyway if you really don't want to make your own presets.


## About VFX:

It's theoretically inadvisable to use the presets in this mod directly in .ini, because ideally every CC mod is self-contained due to the potentially wonky alphabetic loading (what if your mod starts with 00?) but this is the only available way to use these effects outside of Lua.

However: using these presets in scripts specifically is safe. Lua scripts only ever run after all loading is done, which means it doesn't matter when this mod was loaded versus your own.


## About scripts:

Pathing to the scripts directly is fine and simple. If you find they don't work as expected, check inside the script itself for any relevant instructions.


## About sound priority:

Some proposed values:

1: Absolute mission critical
25: Ought be heard every time it plays
75: Important
100: More important than average
128: Default
150: Less important than average
175: Flavor audio - not important
200: Should make room for anything else that plays