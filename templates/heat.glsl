#ifndef MCWR_HEAT_GLSL
#define MCWR_HEAT_GLSL 1

#include "/mcwind/mcwind.glsl"

#ifndef MCWR_HEAT_REACH
#define MCWR_HEAT_REACH 24.0   // Blocks above the source the column still carries. Physical, not stylistic.
#endif
#ifndef MCWR_HEAT_GRAD_STEP
#define MCWR_HEAT_GRAD_STEP 4.0
#endif

struct mcwrHeat {
    float amount; // 0..1 at the source, already faded toward the edge of the data
    float baseY;  // World Y of the hot block underneath
    float known;  // 1 when there is a source here at all, 0 when there is not
};

mcwrHeat GetHeatAt(vec3 worldPos) {
    mcwrHeat h;
    h.amount = 0.0;
    h.baseY  = 0.0;
    h.known  = 0.0;
#ifdef MCWIND
    mcw_Heat raw = mcw_readHeat(worldPos.xz);
    // known false means NO SOURCE FOUND, not zero heat.
    // Never average an unknown in as if it were a cold reading
    // branch on it, or a lava lake at the edge of the data drags the whole average down.
    if (raw.known) {
        // The field only reaches MCW_FIELD_TRUST, 160 blocks. Past that it answers unknown, so
        // fade rather than cut or you get a visible ring around the player as they walk.
        h.known  = 1.0;
        h.baseY  = raw.baseY;
        h.amount = raw.heat * mcw_trustHeat(worldPos.xz, cameraPosition);
    }
#endif
    return h;
}

float HeatRise(mcwrHeat h, vec3 worldPos) {
    if (h.known < 0.5) {
        return 0.0;
    }
    float above = max(worldPos.y - h.baseY, 0.0);
    return h.amount * (1.0 - clamp(above / MCWR_HEAT_REACH, 0.0, 1.0));
}

// FOUR extra field reads. Call it once per particle or per surface, never per raymarch step.
vec2 HeatGradientAt(vec3 worldPos) {
    vec2 g = vec2(0.0);
#ifdef MCWIND
    float e = MCWR_HEAT_GRAD_STEP;
    mcw_Heat px = mcw_readHeat(worldPos.xz + vec2( e, 0.0));
    mcw_Heat nx = mcw_readHeat(worldPos.xz + vec2(-e, 0.0));
    mcw_Heat pz = mcw_readHeat(worldPos.xz + vec2(0.0,  e));
    mcw_Heat nz = mcw_readHeat(worldPos.xz + vec2(0.0, -e));
    g = vec2((px.known ? px.heat : 0.0) - (nx.known ? nx.heat : 0.0),
             (pz.known ? pz.heat : 0.0) - (nz.known ? nz.heat : 0.0)) / (2.0 * e);
#endif
    return g;
}

#endif
