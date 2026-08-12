# Adopting MCWIND - A Dev Guide to WindLink

MCWIND is injected instead and not vendored.

This allows a much smoother ride towards capturing real wind in your shaderpack. 
it allows significantly better development turnover and adoption speed, I can test things
out compatibility with packs quickly and nothing breaks unless the mod itself is broken.

---

## 1. The whole contract

Build `shaders/mcwind/mcwind.glsl`, you **should** write these two comment lines but it shouldn't matter too much.


```glsl
// Deliberately empty. A MCWIND provider replaces the contents of this file at pack load.
// Do not paste anything here and do not delete it.
```

`mcwind.glsl` **must exist and not be deleted** It's the backbone of the entire WindLink Engine that receives all of the
injection data. Removing it will create a compilation failure.

Include this line **anywhere** you want WindLink's functions:

```glsl
#include "/mcwind/mcwind.glsl"
```

In your `shaders.properties` you need to ask for what you want server:

```properties
mcwind.field = true
```

Lastly, branch the call sites for people who don't have the Engine installed:

```glsl
#ifdef MCWIND
    delta = mcw_leafSway(worldPos, blockCentre, weld);
#else
    delta = myOwnLeafWave(worldPos);
#endif
```

---

## 2. Directives

In your `shaders.properties` these are read before the header gets served. They are decisive.

| directive | default | what it does |
|---|---|---|
| `mcwind.field` | off | the foliage responses as well as the channel decode. You want this unless you only want raw data |
| `mcwind.volume` | off | the fog and smoke API. Implies `mcwind.field`, because it is built on the wind field |
| `mcwind.occupancy` | off | the voxel occupancy volume. Costs a texture image unit in every program that includes us |
| `mcwind.lightcells` | off | the light cell volume. Same cost |

---

## 3. What you get

Call these inside `#ifdef MCWIND`.

| function | gives you |
|---|---|
| `mcw_grassHeight(worldPos, blockCentre, upperHalf)` | the height weight the push functions want |
| `mcw_grassPush(blockCentre, heightWeight)` | horizontal bend for a blade |
| `mcw_leafWeld(worldPos, blockCentre)` | how anchored a leaf is to its trunk, 0 to 1 |
| `mcw_leafSway(worldPos, blockCentre, weld)` | full 3D canopy motion |
| `mcw_vineSwing(worldPos, blockCentre, weld)` | hanging growth, added on top of the sway |
| `mcw_stalkSway(worldPos, blockCentre, groundY)` | bamboo and cane, bending about the ground |
| `mcw_fireLean(blockCentre, topWeight)` | flame shear and flicker |
| `mcw_draftPush(blockCentre, cameraPos, heightWeight)` | the kick from something streaming past |
| `mcw_groundHeight(blockCentre, cameraPos)` | surface Y, or -1 outside the trusted radius |
| `mcw_honami(objectNormal, push)` | the bent normal, so a field catches light in travelling bands |
| `mcw_windPhase` | seconds on the wind clock. A macro, and overridable |

**Two important sampling rules**

- **Grass samples at block center,** per vertex sampling will cause them to shear apart.
- **Leaves sample per vertex,** sampling texel centers makes it slab and staircase. Anyone reading this should know that.

---

### Fog and Smoke Behavior

Set `mcwind.volume = true` and you get these analytics.

| function | gives you |
|---|---|
| `mcw_windAt(worldPos, t)` | the wind vector at any point in the air, as `vec3` |
| `mcw_advect(p, t, period)` | two sample positions and a blend weight, for flowmap cycling |
| `mcw_windShear(p, t)` | how hard the flow is deforming here, as one number |
| `mcw_windJacobian(p, t)` | the full velocity gradient, as `mat3` |

**`mcw_advect` exists to save you from creating a noise lookup yourself* and 
returns the two half offset pahses of a flowmap cycle so they can be crossfaded:


```glsl
mcw_Advect adv = mcw_advect(p, mcw_windPhase, 8.0);
float d = mix(myNoise(adv.b), myNoise(adv.a), adv.weight);
```

The reseed phase is jittered by `mcw_gust` a coherent field that travels downwind.
This makes churne read as arrival instead of random blips. The period is quantized so it 
divides the wind clock exaclty so the sky does lurch ever 2hrs 40min. *(Touch grass get some inspiration if you've been on that long.)*

**`mcw_windAt` has a vertical profile** this allows fog or smoke to have that signature hugging effect. It moves
slowly on the ground and moves faster further up. Height gets measured above the real terrain from the ground channel. 
It gives you real data where the channel reaches then falls back to a fixes reference. Fog gets wind everywhere 
and terrain awareness is local to the channel range. Y component is zero, orographic lift is planned but not built yet. 

Dials: `MCW_VOL_REF` (24.0), `MCW_VOL_GROUND` (0.35), `MCW_VOL_SHEAR` (0.30), `MCW_VOL_FALLBACK`, `MCW_VOL_EPS`, `MCW_VOL_JITTER`.

**Do not sample fog at block center.** `mcw_windAt` needs true world position.

`mcw_windAt` is one wind field eval and a ground read. `mcw_advect` is that +
a gust tap. `mcw_windJacobian` is four `mcw_windAt` calls, so it is a compositepass tool, not per vertex.

---

## 4. Uniforms

**You don't need to declare `frameTimeCounter`, `rainStrength` or `worldTime`.** The engine
declares them, and only the ones the translation unit does not already have so it cannot collide
with your own.

**You do need to declare what your own code uses**, `cameraPosition` most likely, exactly as you
already would.

Vertex prerequisites are still yours, and all of them fail if they're wrong: absolute
world coordinates, `at_midBlock` clamped to +/- 2.0 on block id.

---

## 5. Tuning

**Every dial is a `#define` and they are `#ifndef` guarded.** anything defined **above** the include wins:

```glsl
#define MCW_LEAF_AMP 0.8
#define MCW_LEAF_INERTIA 1.2
#include "/mcwind/mcwind.glsl"
```

**Define below the include and it does nothing.** That is the only way to get this wrong.

### A Habit to Follow

Give the player sliders and have them keep your name:

```properties
sliders = MYPACK_LEAF_AMP
screen.CANOPY = MYPACK_LEAF_AMP
```
```glsl
#define MYPACK_LEAF_AMP 0.5 // [0.0 0.2 0.35 0.5 0.8 1.0]
#define MCW_LEAF_AMP MYPACK_LEAF_AMP
#include "/mcwind/mcwind.glsl"
```
Only one line per dial touches default so the defaults moving will never change your look.
Make sure an option exists in **both** `sliders` and a `screen.*` or it becomes unreachable.

### The Leaf/Canopy Dials

| dial | default | what it does |
|---|---|---|
| `MCW_LEAF_AMP` | 0.5 | master canopy amplitude |
| `MCW_LEAF_LEAN` | 0.90 | how far the canopy holds over downwind |
| `MCW_LEAF_STEADY` | 0.24 | leans continuously vs waits for gusts. If turning LEAN up does nothing, this is why |
| `MCW_LEAF_BOUNCE` | 1.0 | the overshoot spring after a gust. 0 removes the snap |
| `MCW_LEAF_INERTIA` | 2.6 | how long a tree takes to notice a gust and to forget one |
| `MCW_LEAF_CALM` | 0.45 | rustle in still air. 0 is a frozen canopy |
| `MCW_LEAF_GUST` | 1.45 | rustle in wind. The other end of the same fade |
| `MCW_LEAF_CHURN` | 1.0 | size of the fine rustle. Peak is about one texel at 1.0 |
| `MCW_LEAF_STIR` | 0.24 | how far the rustle may fade at the bottom of its breath. 0 lets it stop dead |
| `MCW_LEAF_IDLE` | 0.055 | wander in dead calm |
| `MCW_LEAF_CLING` | 0.45 | how hard the trunk holds its leaves |
| `MCW_LEAF_REACH` | 4.0 | distance from wood at which a leaf is fully free |
| `MCW_LEAF_FLOOR` | 0.4 | the least a leaf may move however close to the trunk |
| `MCW_FROND_BEND` / `DROOP` / `EXPOSE` / `TIP` | 1.0 / 1.0 / 0.5 / 1.5 | geometry reaching outside its own block: ferns, palms, bushy-leaf packs |

`MCW_GRASS_AMP`, `MCW_GRASS_IDLE`, `MCW_GRASS_CHURN`, `MCW_GRASS_INERTIA`, `MCW_HONAMI`, `MCW_BREEZE`, `MCW_SWELL`, `MCW_EDDY`, `MCW_DRAFT`, `MCW_STYLE`, `MCW_FIRE_LEAN`, `MCW_FIRE_FLICKER`, `MCW_STALK_BEND`, `MCW_STALK_SPAN`, `MCW_VINE_SWING`. 34 in all.

**`MCW_LEAF_REACH`, `MCW_LEAF_FLOOR` and `MCW_LEAF_CLING` are the weld** it should help with anchoring leaves to the trunk.
Flattening makes the canopy stiff and ridgid and slide off the tree. Looks like a bug like that.

**`MCW_LEAF_COHERENCE` defaults to the player's own mod setting.** You can override theirs with a constant.

Grass, wind and fire have the same shape: `MCW_GRASS_AMP`, `MCW_GRASS_IDLE`, `MCW_GRASS_CHURN`,
`MCW_GRASS_INERTIA`, `MCW_HONAMI`, `MCW_BREEZE`, `MCW_SWELL`, `MCW_EDDY`, `MCW_DRAFT`, `MCW_STYLE`,
`MCW_FIRE_LEAN`, `MCW_FIRE_FLICKER`, `MCW_STALK_BEND`, `MCW_STALK_SPAN`, `MCW_VINE_SWING`. 34 total so far.

---

## 6. Reading the Log

| line | meaning |
|---|---|
| `MCWIND injected N lines into /mcwind/mcwind.glsl: the channel decode and the foliage responses` | working |
| `...: the channel decode only` | you did not set `mcwind.field = true`, so `mcw_leafSway` is not there |
| `this pack ships no /mcwind/mcwind.glsl` | your marker is missing or in the wrong directory |
| `MCWIND ... defined for this pack, because the header was INJECTED into it` | the define agrees with reality |
| `MCWIND injection failed and was skipped` | my bug. Your pack still loads and takes its `#else` |

---

- **Iris only.**
- **`shaders.properties` is yours.**
- **A new channel needs a new `#ifdef` from you.**
- **Injection is at pack load.**
