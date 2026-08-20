# Roadmap

What is planned, by the jar it lands in. Nothing here carries a date, and anything marked *exploring* may not happen at all.

---

## PlunderEngine

The injector, the served header, and the settings screen. Everything a shader pack calls arrives here.

-   **`MCW_VINE_COHERENT`** - a hanging vine reads as one long piece instead of each block swinging on its own. Opt-in define, defaulting off, so an adopted pack does not move.
-   **Grass in eight sections** - a blade bends along its length with stiffness and ground contact, rather than as one arc.
-   **Push settings to the shader** - a button that copies the mod's wind and season values into the selected pack so the two agree, leaving the rest of the pack alone.
-   **Settings screen, remaining steps** - continued work on the config screens.

---

## WindLink

The wind itself: the field, the terrain solve, and how the world reacts to it.

-   **Entity air** - wakes behind anything that moves, a gust when a mob or player lands, and downwash under birds and bees.
-   **Wind gameplay and the server half** - wind that affects play rather than only appearance, authoritative on the server so it agrees for everyone. 
-   **Diagonal sheltering** - wind currently slips through a diagonal gap that should shelter. A fix in the flow solve, not the shader.
-   **Wind visualizer rebuild** - a replacement debug view, because the current one misreports and cannot be trusted for fine tuning.
-   **World responses** - flag trees, banners, dust devils, tumbleweed, windbreaks, and a builder-readable wind value.
-   **Wind masking sound** - wind changing what you hear before any acoustics work.

-   **Curl that decorrelates** - eddies that dissolve and reform instead of holding their shape.  Needs the noise's time axis separated from its spatial one, so it would arrive as an opt-in define.

---

## WeatherLink

Weather as a first-class layer: cells that travel, precipitation that belongs to them.

-   **Particle wind-blown snow** - real snow particles carried by the wind field, so a blizzard streams past you and piles against what shelters it, rather than falling straight through the world. High likely this moves up to WindLink to force agreement with the wind. 
-   **Storm cells you can watch arrive** - rain, storm cores and dust as cells that cross the world and leave, instead of a global on-off.
-   **Precipitation that matches the cell** - the vanilla presentation override, so rain falls where the weather actually is.