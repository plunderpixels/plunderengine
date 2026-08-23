# Adopting MCWIND - A Dev Guide to WindLink

MCWIND is injected instead and not vendored.

This allows a much smoother ride towards capturing real wind in your shaderpack. it allows significantly better development turnover and adoption speed, I can test things out compatibility with packs quickly and nothing breaks unless the mod itself is broken.

---

## 1\. The whole contract

Build `shaders/mcwind/mcwind.glsl`, you **should** write these two comment lines but it shouldn't matter too much.

```glsl
// Deliberately empty. A MCWIND provider replaces the contents of this file at pack load.
// Do not paste anything here and do not delete it.
```

`mcwind.glsl` **must exist and not be deleted** It's the backbone of the entire WindLink Engine that receives all of the injection data. Removing it will create a compilation failure.

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
    delta = mcw_leafSway(worldPos, blockCenter, weld);
#else
    delta = myOwnLeafWave(worldPos);
#endif
```

---

## 2\. Versioning

**Ignore the PlunderEngine and WindLink mod versions.** Those are for players and for the launcher. They move independently to the injection.

`MCWIND_PROVIDER_VERSION`, is what you should look for which is defined in your pack by the injection itself:

```
major * 10000 + minor * 100 + patch
```

It is currently **11300**, which is 1.13.0. It bumps with the provider and never with the mod versions, so this is what you should build against to find out if anyhting has changed.

```glsl
#if MCWIND_PROVIDER_VERSION >= 11100
    mcw_Voxel v = mcw_readVoxel(worldPos, cameraPosition);
#else
    mcw_Voxel v = mcw_readVoxel(worldPos);
#endif
```

11200 added symbols and changed nothing you already call, so it is a minor bump. Gate the new fog ones the same way if you want to keep working against older engines:

```glsl
#if MCWIND_PROVIDER_VERSION >= 11200
    vec3 w = mcw_windAtFast(p, mcw_windPhase);
#else
    vec3 w = mcw_windAt(p, mcw_windPhase);
#endif
```

Both the environment define and the injected text publish the same value, so there is no way to be handed two separate answers

Patch = is a fix with no symbol changes.  
Minor = adds symbols without touching existing ones  
Major = changes the behavior of something you call already and arrives as an optional opt in so it doesn't break your pack on any version.

`MCWIND_PROVIDER_VERSION` only tells you which provider you got.

**The header used to open with** `v0.1 UNSTABLE` **it no longer does.**

**One name changed on the way out, and it is the only one.** `mcw_Advect.weight` is now `mcw_Advect.weightA`. If you built against the fog API in 0.1.13-beta you will need to rename it. This will not be a habitual thing now that MCWIND is **STABLE**.

The `A` is not decoration. **It is the weight of sample `a`**, so `a` goes second in the mix:

```glsl
float d = mix(myNoise(adv.b), myNoise(adv.a), adv.weightA);   // correct
float d = mix(myNoise(adv.a), myNoise(adv.b), adv.weightA);   // backwards, and it compiles
```

The second looks natural but it's wrong. I renamed it because having it backwards causes a bad jump when the age fully wraps around from being handed full weight at the end.

The game now shows the PlunderEngine version and the WindLink and MCWIND versions on the PlunderEngine settings screen, as **MCWIND Injector 1.12.0 (11200)**.

---

## 3\. Directives

In your `shaders.properties` these are read before the header gets served. They are decisive.

| directive | default | what it does |
| --- | --- | --- |
| `mcwind.field` | off | the foliage responses as well as the channel decode. You want this unless you only want raw data |
| `mcwind.volume` | off | the fog and smoke API. Implies `mcwind.field`, because it is built on the wind field |
| `mcwind.occupancy` | off | the voxel occupancy volume: solidity, light connectivity and air connectivity. Costs a texture image unit in every program that includes us |
| `mcwind.lightcells` | off | the light cell volume. Same cost |
| `mcwind.weather` | off | the weather decode: storm cells, snow bands, precipitation edges. Implies nothing, because it reads published uniforms and calls no field maths, so a sky pack can take it without buying foliage wind it will never call |

---

## 4\. What you get

Call these inside `#ifdef MCWIND`.

| function | gives you |
| --- | --- |
| `mcw_grassHeight(worldPos, blockCenter, upperHalf)` | the height weight the push functions want |
| `mcw_grassPush(blockCenter, heightWeight)` | horizontal bend for a blade |
| `mcw_leafWeld(worldPos, blockCenter)` | how anchored a leaf is to its trunk, 0 to 1 |
| `mcw_leafSway(worldPos, blockCenter, weld)` | full 3D canopy motion |
| `mcw_vineSwing(worldPos, blockCenter, weld)` | hanging growth, added on top of the sway |
| `mcw_stalkSway(worldPos, blockCenter, groundY)` | bamboo and cane, bending about the ground |
| `mcw_pendantSwing(worldPos, blockCenter)` | a hanging lantern and the chain it hangs on, as one pendulum planted at its anchor |
| `mcw_pendantLight(blockCenter)` | the offset to add to that lantern's LIGHT position, so the glow moves with the lamp |
| `mcw_fireLean(blockCenter, topWeight)` | flame shear and flicker |
| `mcw_rainLean(worldPos, topWeight)` | falling rain tilted into the wind |
| `mcw_draftPush(blockCenter, cameraPos, heightWeight)` | the kick from something streaming past |
| `mcw_groundHeight(blockCenter, cameraPos)` | surface Y, or -1 outside the trusted radius |
| `mcw_honami(objectNormal, push)` | the bent normal, so a field catches light in traveling bands |
| `mcw_windPhase` | seconds on the wind clock. A macro, and overridable |

**`mcw_rainLean` is for your weather program.** Add it to the vertex position of a rain or snow quad, with `topWeight` running 1 at the top of the streak and 0 at the bottom:

```glsl
vec4 pos = gl_Vertex;
vec3 world = pos.xyz + cameraPosition;
float topWeight = clamp(pos.y / 16.0 + 0.5, 0.0, 1.0);
pos.xyz += mcw_rainLean(world, topWeight);
```

**Do not take that weight from `texcoord.y`.** Vanilla animates rain by scrolling the texture's V, so it is not 0..1 across a quad.

**Snow is deliberately left alone and returns zero.** A snowflake sprite has no falling streak to tilt, the sprite looks extremely broken. Blown snow want's realistic particles, the basic version way be released through WindLink via an opt-in in the future.

The tilt is horizontal wind speed over fall speed, its clamped so a storm is unable to lay the rain flat.

`MCW_RAIN_LEAN` defaults to **3.0** that is in the middle. Other dials: `MCW_RAIN_FALL` (1.0) and `MCW_RAIN_MAX` (3.0).

Sample it at the quad's true world position not a block center. Rain is not block-aligned and snapping it would band the lean across the sky.

You can already shear your own weather, of course. What this gives you is that the shear **agrees with the grass, the fog and the dust in the same frame**.

**Two important sampling rules**

-   **Grass samples at block center,** per vertex sampling will cause them to shear apart.
-   **Leaves sample per vertex,** sampling texel centers makes it slab and staircase. Anyone reading this should know that.

---

### The Channel Decode

The functions above are the foliage responses, which comes from `mcwind.field`. Underneath them are the channel decodes, which is from the marker file alone. These are the raw read outs that the response comes from. You can use them for anything really. *I'm only suggesting for what.*

Every one returns a struct whose first member is `known`. **`known == false` means the channel doesn't have data for it** or no producer for it. If outside its trusted radius, or the feature is switched off in the player's settings it will show false so as not to break things. It never means zero. **Build fallbacks for false.**

| function | returns |
| --- | --- |
| `mcw_readClock()` | `{ bool known; float seconds; }` the wind clock |
| `mcw_readCtl()` | `{ bool known; float drive; float strength; float gustFloor; float flash; }` the player's dials |
| `mcw_readSeason()` | `{ bool known; float phase; }` phase 0..4, spring through winter |
| `mcw_readBolt()` | `{ bool known; bool snow; vec3 dir; }` lightning direction and whether it is snowing |
| `mcw_readCover()` | `{ bool known; bool modDrawsGrass; }` whether the mod is drawing its own grass. **Always false since 1.1.15**: the mod-drawn ground cover was cut, so nothing claims that render any more. The channel stays declared and keeps answering, so a pack already branching on it needs no change |
| `mcw_readSpriteMetrics()` | `{ bool known; float shortBlade; float tallBlade; }` blade heights from the active resource pack |
| `mcw_readFlow(worldXZ)` | `{ bool known; float speed; vec2 deflect; }` terrain wind flow |
| `mcw_readGround(worldXZ)` | `{ bool known; float y; float loose; }` surface Y and how loose the ground is |
| `mcw_readWood(worldXZ)` | `{ bool known; float dist; }` distance to the nearest wood |
| `mcw_readDraft(worldXZ)` | `{ bool known; vec2 push; }` the kick from passing entities |
| `mcw_readHeat(worldXZ)` | `{ bool known; float heat; float baseY; }` heat sources and their base |
| `mcw_readWater(worldXZ)` | `{ bool known; float open; float surfaceY; float cls; float shoreDist; }` |
| `mcw_readImpulse(i)` | `{ bool known; vec2 pos; float age; float strength; vec2 dir; float seed; float size; }` |

Each has a matching `mcw_trust*(worldXZ, cameraPos)` where it makes sense - `mcw_trustFlow`, `mcw_trustGround`, `mcw_trustWood`, `mcw_trustHeat`, `mcw_trustWater`, `mcw_trustDraft`, `mcw_trustOccupancy` returning 1 near the camera and falling to 0 at the edge of that channel's range. The fade makes it less noticeable. Fade with those instead of branching on `known` as a hard edge.

**Seasons are OFF by default and that is deliberate.** Recolored biomes are extremely visible, so it is opt in. That means `mcw_readSeason().known` is **false on a default install.  
DO NOT LEAN ON IT** it will be moved to a future weather based mod. I am undecided on how seasonal wind will integrate so it may very well get ripped.  
This is the only remaining **UNSTABLE** feature.

**`mcw_readWater` carries the shore.** `cls` is the water class and `shoreDist` is the distance to the nearest shore in blocks, both alongside `open` and `surfaceY`. They used to be packed onto the block id, which cost you a lookup (and a whole lot more on [Complementary](https://www.complementary.dev/shaders/)) they are in the channel now.

**`MCW_LEAF_COHERENCE` follows the player.** It defaults to `mcw_leafCoherenceAmount()`, which is the "trees move as one" setting from the mod's own menu. A canopy can hold together coherently or break apart depending on taste. *Define it to a constant above the include if your pack needs to own that decision.*

---

### Fog and Smoke Behavior

Set `mcwind.volume = true` and you get these analytics.

| function | gives you |
| --- | --- |
| `mcw_windAt(worldPos, t)` | the wind vector at any point in the air, as `vec3` |
| `mcw_windAt(worldPos, t, gy, wall, flow)` | the same vector with the terrain terms handed in |
| `mcw_windAtFast(worldPos, t)` | the cheap tier, for raymarched fog |
| `mcw_windAtFast(worldPos, t, gy, flow)` | the cheap tier with the terrain terms handed in |
| `mcw_advect(p, t, period)` | two sample positions and `weightA`, the blend weight for sample `a` |
| `mcw_windShear(p, t)` | how hard the flow is deforming here, as one number |
| `mcw_windJacobian(p, t)` | the full velocity gradient, as `mat3` |
| `mcw_volWallAt(worldPos)` | wall distance with curl on, a constant with it off |

**`mcw_advect` exists to save you from creating a noise lookup yourself** and returns the two half offset phases of a flowmap cycle so they can be crossfaded:

```glsl
mcw_Advect adv = mcw_advect(p, mcw_windPhase, 8.0);
float d = mix(myNoise(adv.b), myNoise(adv.a), adv.weightA);
```

The blend field is `weightA` and it belongs to sample `a`, which is why `b` comes first in that `mix`. *See versioning for reason*

The reseed phase is jittered by `mcw_gust` a coherent field that travels downwind. This makes churn read as arrival instead of random blips. The period is quantized so it divides the wind clock exactly so the sky does **not** lurch every 2hrs 40min. *(Touch grass get some inspiration if you've on long enough to witness. This is a personal reminder.)*

**`mcw_windAt` has a vertical profile** this allows fog or smoke to have that signature hugging effect. It moves slowly on the ground and moves faster further up. Height gets measured above the real terrain from the ground channel. It gives you real data where the channel reaches then falls back to a fixed reference. Fog gets wind everywhere and terrain awareness is local to the channel range.

**Orographic lift is built.** The Y component is no longer zero. Wind crossing rising ground gets pushed up, wind crossing falling ground gets pulled down. The effect ends up decaying with height above the terrain so fog hugs a slope instead of climbing it forever. It comes from the ground channel. So it reads real terrain.

Dials: `MCW_VOL_REF` (24.0), `MCW_VOL_GROUND` (0.35), `MCW_VOL_SHEAR` (0.30), `MCW_VOL_FALLBACK`, `MCW_VOL_EPS`, `MCW_VOL_JITTER`, `MCW_VOL_DRIFT`.

Lift dials: `MCW_VOL_LIFT` (1.0, 0 switches it off), `MCW_VOL_LIFT_SPAN` (3.0, how far apart the slope is measured), `MCW_VOL_LIFT_FADE` (24.0, the height it decays over), `MCW_VOL_LIFT_MAX` (1.0, the clamp).

**3D curl is built too, and it is off unless you ask.** `MCW_VOL_CURL` ships at 0, so `mcw_windAt` returns exactly what it returns without it. Set it and the wind gains divergence-free churn scaled by your local wind speed, so still air stays still. 0.5 is a starting point, 1.0 is plainly turbulent.

It arrives as a **whole vector** and moves your horizontal wind too. Keep one component of a curl and it stops being divergence-free, and a flow that can compress is what piles volumetric fog into patches that come and go. The lift above is kinematic and this term is not: a persistent froxel sim leans on this one.

Set `mcwind.occupancy = true` as well and the churn is shaped by distance to the nearest solid, so an eddy tightens against a wall a few blocks out. Without it you get free-stream churn everywhere, which is correct rather than broken. `mcw_volCurlAt(worldPos, groundY, t, speed)` is the term on its own, and a fifth argument takes the wall distance if you already hold one. `mcw_volCarryAt(worldPos, groundY, wallDist)` is the anchor blend it uses: 0 pinned to terrain, 1 fully carried by the wind. Pass the ground height you already have from `mcw_groundHeight`, or -1 for free air.

**The curl comes from the noise's own gradients, not differencing.** Same corner hashes, closed form derivative, a quarter of the hashes, and **exactly** divergence-free rather than divergence-free to the square of an epsilon. One limit, stated precisely because persistent sims are why this exists: you get back curl times speed times wall shaping, both vary in space, so the shear layer against a wall picks up a little divergence from the scaling's own gradient. If yours has to be airtight, sample the curl at constant strength and shape your **density** instead of your velocity.

**The eddies ride the wind in free air and pin to terrain near it.** The sample position is carried by the same published drift `mcw_advect` uses, so high structure travels downwind instead of sitting in world coordinates, while near the ground or a wall it stays put, because a shear layer belongs to the ridge that sheds it. The blend runs over `MCW_VOL_CURL_ANCHOR` (16.0) in height above ground, or the wall reach with occupancy on, whichever surface is closer. That is also the evolution: an eddy holds its shape, but air crossing a ridge moves *through* the anchored structure, so a parcel sees the field change continuously. Eddies that genuinely dissolve and reform are your own time axis on top. The wall shaping reads the true position throughout, since a wall does not travel with the air.

**Curl is for packs that carry state across frames.** Judged in game: at full strength it plainly restructures the wind field, and it is indistinguishable from off if all you do is offset a noise lookup through `mcw_advect`. A smooth warp of a noise looks like a different noise, and a stateless flowmap cannot accumulate a swirl however big it is. This term stops a froxel sim's advected density piling up; if you are warping noise, leave it at zero and spend the taps elsewhere.

Curl dials: `MCW_VOL_CURL` (0.0) and `MCW_VOL_CURL_ANCHOR` (16.0).

**Do not sample fog at block center.** `mcw_windAt` needs true world position.

**Costs.** `mcw_windAt` is one wind field eval and three ground reads. `mcw_advect` adds a gust tap. `mcw_windJacobian` is four `mcw_windAt` calls, a composite pass tool, never per vertex. Curl adds three gradient taps of eight hashes each, plus a wall search of up to twenty-five voxel reads with occupancy on. **Raising `MCW_VOL_CURL` above zero is what arms both**; at the default `mcw_volWallAt` folds to a constant and no occupancy read happens at all.

**The Jacobian holds its own terms.** Ground height, wall distance and terrain flow are read once at `p` and shared across the four samples through the five argument `mcw_windAt`, because all three are piecewise constant, the wall in three block treads against a 0.75 block epsilon, and differencing them gave zeros on the treads and spikes at the edges instead of a gradient. Do the same in any stencil of your own, and **never difference `mcw_wallDistance`, `mcw_groundHeight` or `mcw_flowAt`** by hand.

**Marching per step? Take `mcw_windAtFast`.** Four noise evals against `mcw_windAt`'s six; it keeps the vertical profile, the lift, the presets and the player's wind character dials, and skips the curl and the wall walk by construction. The four argument form resolves the ground and flow reads once per **ray** and pays only ALU per step:

```glsl
float gy   = mcw_groundHeight(rayStart, cameraPosition);
vec3  flow = mcw_flowAt(rayStart);
vec3  w    = mcw_windAtFast(rayStart, mcw_windPhase, gy, flow);
```

**IMPORTANT.** The field varies over tens of blocks, so sampling it per step is a waste. Sample the wind once per ray or once per froxel column, march your noise per step, and the field's cost stops being a question. What the fast tier actually costs you is the two finest octaves of the gust cascade, which fog at raymarch resolution can't show you anyway.

---

### Occupancy and Light Cells

Set `mcwind.occupancy = true` for the voxel volume and `mcwind.lightcells = true` for the light volume. Each costs a texture image unit in every program that includes mcwind, so switch on only what you read.

| function | gives you |
| --- | --- |
| `mcw_readVoxel(worldPos, cameraPos)` | `mcw_Voxel { bool known; bool solid; bool sky; bool support; float depth; }` |
| `mcw_readAir(worldPos, cameraPos)` | `mcw_Air { bool known; bool sky; float depth; }` |
| `mcw_readLightCell(worldPos, cameraPos)` | `mcw_LightCell { bool known; vec3 rgb; float level; }` |
| `mcw_inOccupancy(worldPos, cameraPos)` | whether the volume covers this position at all |
| `mcw_trustOccupancy(worldXZ, cameraPos)` | 1 near the camera falling to 0 at the window edge, for fading |

`solid` is the block being there. `support` is anything a plant could hang from - leaves, glass, slabs, stairs, fences - none of which is solid.

**The volume answers connectivity twice, and the difference is the point.**

`sky` and `depth` are **light**. The fill is stopped by `solid` alone, so it walks through a window and a glazed room reads outdoors. `depth` is 0..31 to the nearest sky voxel, measured through the volume: cave darkness without a raymarch.

`mcw_readAir` is **air**, added in 1.13.0. Stopped by `solid` **or** `support`, so glass and doors seal. `depth` is 0..127 measured **through air** from daylight - 0 outdoors, climbing as you walk in, pinned at 127 in a sealed room. It is breadth-first, so its negative gradient points at the opening. Its own struct because GLSL constructs positionally: fields added to `mcw_Voxel` would break any pack with a `mcw_Voxel(false, false, false, false, 0.0)` fallback.

Light for how bright somewhere is, air for whether wind or fog could reach it. `mcw_caveCalm` is the air pair already turned into a multiplier, and is probably what you want.

**Always pass the camera. IMPORTANT**

The volume is world-anchored in X and Z: a texel address is `worldXZ mod 96`, so the coordinate IS the address and the window follows you without any origin to publish. Vertically it is 64 slices that move with the camera, which is why `mcw_occBaseY` has to exist at all.

The consequence is that **the horizontal address wraps rather than fails**. A position outside the 96 block window aliases onto a different column that IS in the window, and comes back with `known == true` carrying that other column's data. There is no way for a reader given only a world position to tell the two apart, so the single argument forms `mcw_readVoxel(worldPos)` and `mcw_readLightCell(worldPos)` cannot bounds check and do not try. They still exist, and they are still correct inside the window, but the prefered arguments are:

```glsl
#if MCWIND_PROVIDER_VERSION >= 11100
    mcw_Voxel v = mcw_readVoxel(worldPos, cameraPosition);   // known is false outside the window
#else
    mcw_Voxel v = mcw_readVoxel(worldPos);                   // known is Y only; check XZ yourself
#endif
if (!v.known) {
    // outside the volume, or the producer has not run. Fall back, do not treat it as empty air.
}
```

The window is 96 blocks square, so the two argument forms return `known = false` beyond 48 blocks from the camera on either axis. If you are shading something continuous and a hard edge would show, fade with `mcw_trustOccupancy` instead of branching on `known`.

**`known == false` is a real answer and it is not "empty".** It means the volume cannot speak for this position. This is a failsafe so you don't read it as air which would cause some breakage.

---

### Wind in Caves

The field is a heightmap: an interior column reads as its own rooftop and the shelter term is floored, so **it cannot answer "no wind" underground** and cave foliage reacts to a surface storm. You cannot tune around it, because the dial you would turn down is the one making the surface work.

`mcw_caveCalm(blockCenter)` answers it off the air pair: 1 outdoors, falling toward `MCW_CAVE_DRIFT` as you go in. **Applied for you inside every response**, so nothing changes at your call sites.

| define | default | what it does |
| --- | --- | --- |
| `MCW_CAVE_CALM` | `0.0` | strength, 0..1. **Zero, so nothing changes until you ask.** At 0 the voxel read folds away as dead code |
| `MCW_CAVE_SPAN` | `8.0` | blocks of air from daylight before the wind is fully gone |
| `MCW_CAVE_DRIFT` | `0.02` | what is left deep inside. Zero reads as no motion at all |

Needs `mcwind.occupancy`. Without it every read is unknown and the gate answers 1.0 everywhere: a missing channel is no gate, never a lockdown. This solution leaves the door open for my future cave wind behavior.

### Gusts, and Gusts Arriving

`mcw_gustRise(cellXZ, mcw_windPhase)` is the leading edge of a front: 0 in steady wind, positive while the gust builds, never negative. It is what makes an arrival read as an arrival rather than the wind just being stronger.

The vine responses take it behind two defines, both **`0.0` by default** so your vines are byte-identical until you set them:

| define | default | what it does |
| --- | --- | --- |
| `MCW_VINE_GUST` | `0.0` | 0..1, how far the hanging swing blends from the smoothed gust to the live one |
| `MCW_VINE_SURGE` | `0.0` | how hard the leading edge shoves. `mcw_grassPush` uses 1.8 on the same term |

### Hanging Lanterns and Chains

Lantern hanging swings, chain hanging swings, and chains with a lantern hanging from it swings together. `mcw_pendantSwing` decides which by reading the world, so it needs `mcwind.occupancy = true`.

```glsl
// one material id for the lantern AND the chain, no argument between them
position.xyz += mcw_pendantSwing(worldPos, blockCenter);
```

**Give them ONE id.** They take the same call with the same arguments and do not differ, so a second id is only a second place for them to drift apart. Shipping them split is how you get a floting lanter.

**Tag the STATE, not the block.** A lantern on the floor is bolted to the floor and a chain lying along x or z is a strut between two walls.

**Lanterns have mass.** so they behave

Rocking between gusts is derived by noise so it doesn't appear like a canned animation.

It takes wind to cause the lantern to lean, a lot more than vines. Doubling the wind speeds increases lean by about 3 degrees.

The shove only happens on a gust front. Below `MCW_PENDANT_FRONT` the lantern does not notice the wind changing. This keeps lanterns with a little more memory as the wind shifts due to mass.

**`MCW_PENDANT_FRONT` is in gust per SECOND.** The slope of the smoothed gust sits at 0.014 per second half the time and only reaches 0.066 in the top. So one per-second threshold means the same physical wind event for a two-link hang and a ten-block one. Per swing instead and a long chain is shoved by ordinary breathing while a short one ignores a storm.

**A LONGER CHAIN SWINGS SMALLER, NOT BIGGER.** The swing you see is one angle times each vertex's own drop below the anchor, so an angle that ignored the length would have a ten block chain move ten times as far as a one block hang. The angle therefore falls by the square root of the strand length, the same root the period rises by: a longer pendulum is a slower one, and a slower one takes less out of a broadband gust field. The bottom of a ten block chain ends up moving about three times as far as a one block hang rather than ten times.

**`MCW_PENDANT_MEMORY` is in SWINGS rather than seconds** for the same class of reason. Tying the history window to the pendulum's own period keeps the kernel sampled the same number of times per swing, so a short hang reads as a crisp fast swing instead of as aliased noise.

| define | default | what it does |
| --- | --- | --- |
| `MCW_PENDANT_FRONT` | `0.08` | how fast the gust must change, per second, before the lantern notices. The mass dial |
| `MCW_PENDANT_SWAY` | `1.0` | how far a front throws it once it has noticed one |
| `MCW_PENDANT_IDLE` | `1.0` | the rock it rests in between fronts. Zero hangs it dead still |
| `MCW_PENDANT_HANG` | `1.0` | the steady angle the wind holds it at |
| `MCW_PENDANT_PERIOD` | `1.15` | seconds for one swing out and back, for a strand one block long. Longer strands are slower by the square root of their length, and swing through a smaller angle by the same root |
| `MCW_PENDANT_DAMP` | `0.85` | how much of the swing is gone after one pass |
| `MCW_PENDANT_MEMORY` | `1.3` | how much wind the shove is built from, in swings |
| `MCW_PENDANT_TAPS` | `5` | how finely that wind is read. The only one that costs frames per vertex |
| `MCW_PENDANT_RADIUS` | `0.35` | HOW FAR IT MAY TRAVEL, in blocks, measured at the bottom of the strand. New in 1.1.17 |
| `MCW_PENDANT_KNEE` | `0.6` | the fraction of that bound where it starts easing off. New in 1.1.17 |

`MCW_PENDANT_LEAN_MAX` and `MCW_PENDANT_SWAY_MAX` cap the two angles inside the helper. Do not scale the result again outside. The cap is there so a cranked dial cannot lay a lamp flat.

**`MCW_PENDANT_RADIUS` is the third bound and the only one in BLOCKS.**

**You may scale it.** The value you set is multiplied by `mcw_dialPendantRadius`, which is the player's own dial and reads `1.0` when no provider is present, so your number stands on its own and a player who thinks a lamp swings too far can still say so without editing your pack.

`mcw_pendantHang(blockCenter, below, strand)` is the bare pendulum if you already know your own anchor, and `mcw_pendantHold` and `mcw_pendantDrive` are the parts if you want them. Every form takes an optional trailing `float stiffness`, forwarding `MCW_PENDANT_STIFF` when omitted.

### Moving the Light With It

```glsl
// wherever your pack writes a block light into its voxel grid
vec3 lightPos = blockCenter + mcw_pendantLight(blockCenter);
```

One call, one argument. A light voxelization pass has no vertex and no entity id, so anything more is work you should not have to do. It is the same swing the mesh takes, sampled at the block center because that is where the flame sits, so the glow and the geometry cannot disagree. Do not compute it a second way.

If your pack voxelizes block light, which most packs with colored lighting do, this moves it and you are done. If it doesn't, keep `MCW_PENDANT_HANG` modest so the mismatch stays under notice.

## 5\. Uniforms

**You don't need to declare `frameTimeCounter`, `rainStrength` or `worldTime`.** The engine declares them, and only the ones the translation unit does not already have so it cannot collide with your own.

**If you set `mcwind.volume = true` you don't need to declare `cameraPosition` either**, for the same reason: the volume half asks for it and the engine adds it if your translation unit does not already have it.

**Everything else your own code uses is still yours to declare**, exactly as you already would.

Vertex prerequisites are still yours, and all of them fail if they're wrong: absolute world coordinates, `at_midBlock` clamped to +/- 2.0 on block id.

---

## 6\. Tuning

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

Only one line per dial touches default so the defaults moving will never change your look. Make sure an option exists in **both** `sliders` and a `screen.*` or it becomes unreachable.

### The Leaf/Canopy Dials

| dial | default | what it does |
| --- | --- | --- |
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

`MCW_GRASS_AMP`, `MCW_GRASS_IDLE`, `MCW_GRASS_CHURN`, `MCW_GRASS_INERTIA`, `MCW_HONAMI`, `MCW_BREEZE`, `MCW_SWELL`, `MCW_EDDY`, `MCW_DRAFT`, `MCW_STYLE`, `MCW_FIRE_LEAN`, `MCW_FIRE_FLICKER`, `MCW_FIRE_INERTIA`, `MCW_STALK_BEND`, `MCW_STALK_SPAN`.

**Vines got their own big happy family.** Eighteen dials covering both directions, because a vine climbing a wall and a vine hanging off a ceiling need different behaviors: `MCW_VINE_STIFF`, `MCW_VINE_SWING`, `MCW_VINE_ANCHOR`, `MCW_VINE_PEEL`, `MCW_VINE_SEARCH`, `MCW_VINE_HELD`, `MCW_VINE_HANG`, `MCW_VINE_HANG_SPAN`, `MCW_VINE_LOOSEN`, `MCW_VINE_FULL`, `MCW_VINE_REACH`, `MCW_VINE_BLIND`, `MCW_VINE_DANGLE`, `MCW_VINE_DANGLE_MAX`, `MCW_VINE_FREE`, `MCW_VINE_DRIFT`, `MCW_VINE_RISE_STIFF`, `MCW_VINE_RISE_BLIND`.

**`MCW_LEAF_WELD_MISS` (1.0) is the one to know about.** It is what `mcw_leafWeld` answers when it cannot find any wood in the column.

**`MCW_LEAF_REACH`, `MCW_LEAF_FLOOR` and `MCW_LEAF_CLING` are the weld** it should help with anchoring leaves to the trunk. Flattening makes the canopy stiff and rigid and slide off the tree. Looks like a bug like that.

**`MCW_LEAF_COHERENCE` defaults to the player's own mod setting.** You can override theirs with a constant.

Grass, wind and fire have the same shape as the canopy dials above.

Rain adds `MCW_RAIN_LEAN` (3.0), `MCW_RAIN_FALL` (1.0) and `MCW_RAIN_MAX` (3.0).

Vines add the eighteen `MCW_VINE_*` dials, and leaves add `MCW_LEAF_WELD_MISS`.

The fog and smoke half adds `MCW_VOL_REF`, `MCW_VOL_GROUND`, `MCW_VOL_SHEAR`, `MCW_VOL_FALLBACK`, `MCW_VOL_EPS`, `MCW_VOL_JITTER`, `MCW_VOL_DRIFT`, `MCW_VOL_CURL`, `MCW_VOL_CURL_ANCHOR` and the four `MCW_VOL_LIFT*` dials. The weather half adds `MCW_WX_EDGE`, `MCW_WX_SNOW_BAND`, `MCW_WX_MAX_CELLS` and `MCW_WX_NO_UNIFORMS`.

**73 overridable dials in all**, counting every `#ifndef` guarded define across the four halves: 56 in the field half, 13 in the fog and smoke half, 4 in the weather half, and none in the marker file's own decode. Which of them exist in your pack depends on which directives you set, so a dial from a half you did not ask for is simply not there.

---

## 7\. Reading the Log

| line | meaning |
| --- | --- |
| `MCWIND injected N lines into /mcwind/mcwind.glsl: the channel decode and the foliage responses` | working |
| `...: the channel decode only` | you did not set `mcwind.field = true`, so `mcw_leafSway` is not there |
| `this pack ships no /mcwind/mcwind.glsl` | your marker is missing or in the wrong directory |
| `MCWIND ... defined for this pack, because the header was INJECTED into it` | the define agrees with reality |
| `MCWIND injection failed and was skipped` | my bug. Your pack still loads and takes its `#else` |

---

-   **Iris only.**
-   **`shaders.properties` is yours.**
-   **A new channel needs a new `#ifdef` from you.**
-   **Injection is at pack load.**