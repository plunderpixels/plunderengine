#ifndef MCWR_ADVECT_GLSL
#define MCWR_ADVECT_GLSL 1

// Requires `mcwind.volume = true` in shaders.properties. Without it mcw_advect is not injected
// and this will not compile.

#include "/mcwind/mcwind.glsl"

#ifndef MCWR_ADVECT_PERIOD
#define MCWR_ADVECT_PERIOD 20    // Seconds a parcel is carried before the cycle restarts
#endif

struct mcwrAdvect {
    vec3  a;
    vec3  b;
    float weight; // 1 takes a alone, 0 takes b alone
};

mcwrAdvect GetAdvect(vec3 worldPos) {
    mcwrAdvect o;
    o.a = worldPos;
    o.b = worldPos;
    o.weight = 1.0;
#ifdef MCWIND
    // mcw_volPeriod snaps the period so it divides the wind clock evenly. Pass a raw number
    // instead and the cycle jumps every time that clock wraps.
    mcw_Advect m = mcw_advect(worldPos, mcw_windPhase, mcw_volPeriod(float(MCWR_ADVECT_PERIOD)));
    o.a = m.a;
    o.b = m.b;
    o.weight = m.weightA;
#endif
    return o;
}

// The drift is ALREADY inside a and b. Do not subtract mcw_windDriftX/Z yourself on top of this
// or the volume travels at double speed and the two halves disagree about where they are.
// That is TWO noise evaluations per sample. It is the whole cost of this technique and there is
// no cheaper version: one sample cannot cross-fade with itself. Budget for it before you commit,
// and if a raymarch cannot afford it, use a rigid offset and accept that it will not deform.

float AdvectShear(vec3 worldPos) {
#ifdef MCWIND
    return mcw_windShear(worldPos, mcw_windPhase);
#else
    return 0.0;
#endif
}

#endif
