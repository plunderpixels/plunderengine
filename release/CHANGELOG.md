# Changelog

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