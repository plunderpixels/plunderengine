# Changelog

## 1.1.17

`MCWIND_PROVIDER_VERSION` **11300**, unchanged from 1.1.16.

No new symbols.

**WindLink now requires PlunderEngine `0.1.17`.** 

-   **`mcw_hasOccupancy()` now answers for your pack, not for the mod.** It is gated on `MCW_OCCUPANCY` and returns `false` when you never enabled the channel.
-   **`MCW_PENDANT_RADIUS` bounds a lantern's swing in BLOCKS.** Default `0.35`, measured at the bottom of the strand, and multiplied by `mcw_dialPendantRadius` so a player can scale it without editing your pack. 
-   **Hanging signs swing with no need for pack support.**
-   **Full grown wheat sheds husk, loose grain and broken straw.** Each with it's own weight.
-   **Blown debris fades out instead of just disappearing.**
-   **Blade and chaff colors follow a resource pack change without a restart.** 

## 1.1.16

`MCWIND_PROVIDER_VERSION` **11300**, was 11200 in 1.1.15.

Minor bump. Every changed body is behind a define that ships off, and the new symbols need none. Hanging lanterns, cave wind calmed down, flicker fixes on vine.

-   **Hanging lanterns and chains swing, as one object.** `mcw_pendantSwing(worldPos, blockCenter)`Needs `mcwind.occupancy`.
-   **`mcw_pendantLight(blockCenter)` moves the glow with the lamp.** Not in ref pack as there is no lighting in it.
-   **`mcw_pendantHang(blockCenter, below, strand)` if you already know your own anchor**, plus `mcw_pendantHold` and `mcw_pendantDrive` if you want the parts. Dials are `MCW_PENDANT_FRONT`, `_SWAY`, `_IDLE`, `_HANG`, `_PERIOD`, `_DAMP`, `_MEMORY` and `_TAPS`; `_TAPS` is the only one that costs frames and it costs them per vertex.
-   **Wind stops at the cave mouth.** `mcw_caveCalm(blockCenter)` off a new AIR byte on `mcw_occupancy`: a second connectivity fill blocked by anything that stops motion so glass seals wind while daylight still reads outdoors. Applied inside every response, so no call-site changes. `MCW_CAVE_CALM` defaults to `0.0`; needs `mcwind.occupancy`.
-   **`mcw_readAir(worldPos, cameraPos)`** for the raw data: `sky` is air-connected, `depth` is 0..127 blocks of air from daylight. Its own struct, so `mcw_Voxel` is byte-identical and no positional constructor breaks.
-   **Vines answer a gust arriving.** `mcw_gustRise` is the leading-edge term `mcw_grassPush` already used; the hanging swing was reading a smoothed gust that no front ever showed on. `MCW_VINE_GUST` and `MCW_VINE_SURGE`, both default `0.0`.
-   **Banners now wave.** They blow in the wind and flex. Cloth has five hinged bands, on by default all mod-side. Four new dials in foliage settings.
-   **`mcw_occupancy` is RG8, was R8.** Only matters if you declare the sampler yourself; `.r` is the same byte it always was.
-   **The one behavior change: `mcw_vineSwing`'s amplitude curve.** Adjust the curve to become more adapted to the wind.

## 1.1.15

`MCWIND_PROVIDER_VERSION` **11200**, was 11100 in 0.1.14.

Minor bump. Symbols added, nothing you already call behaves differently.

-   **`mcw_windAtFast` for raymarched fog.** A four argument form resolves the ground and flow reads once per ray. Sample the wind once per ray and march your own noise per step.
-   **The Jacobian stopped differencing step functions.** Ground, wall and flow now read once through a new five argument `mcw_windAt` . Roughly a quarter of the texture reads. Reported from outside by **Koteinik**, thanks G.
-   **The curl is analytic.** Built from the noise's gradients rather than differenced, so a quarter of the hashes and exactly divergence free instead of nearly.
-   **Vines got eighteen dials and a fix.** Hanging plants are anchored at the ceiling. Upright vines now compute the inverse. Dial everything to your liking.
-   **Strands feature got cut from WindLink** see mods like Grassier Grass for a comparable and arguably significantly better feature.

## 0.1.14

`MCWIND_PROVIDER_VERSION` **11100**, was 11000 in 0.1.13-beta.

STABLE

-   **BREAKING, and the only one: `mcw_Advect.weight` is now `mcw_Advect.weightA`.** Rename the field, you are done. The `A` means it is the weight of sample `a`, so `a` goes second: `mix(noise(adv.b), noise(adv.a), adv.weightA)`. Putting `a` first compiles and looks more natural, and makes the fog lurch twice a cycle.
-   **The header no longer says `v0.1 UNSTABLE`.** Names are fixed from here. Anything that changes what an existing symbol does will arrive as an opt-in define.
-   **Occupancy reads can be bounds-checked.** `mcw_readVoxel(worldPos, cameraPosition)` returns `known = false` outside the window instead of another column's data wearing a straight face. Same for `mcw_readLightCell`, plus `mcw_trustOccupancy` to fade at the edge.
-   **`mcw_windAt` returns a real Y.** Orographic lift off the terrain: wind climbs a windward face, sinks on the lee, fades with height. This shipped in 0.1.13 and the docs said it had not.
-   **3D curl, opt-in.** `MCW_VOL_CURL`, default 0, so nothing moves unless you ask. It is for packs that carry density across frames; it is a no-op through a stateless flowmap.
-   **`mcw_rainLean(worldPos, topWeight)`.** Falling rain tilted into the same wind the grass bends to. Snow returns zero on purpose shearing it just slides the sprite.
-   **There is a worked example of `mcw_rainLean` in the jar.** The bundled reference pack gained a `gbuffers_weather` program that calls it unzip the jar and look under `assets/plunderengine/reference-pack/shaders/`.
