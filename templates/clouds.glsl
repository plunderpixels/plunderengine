// Needs `mcwind.volume = true` in shaders.properties, or none of this is injected.

#ifndef MCWR_CLOUD_GLSL
#define MCWR_CLOUD_GLSL 1

#include "/mcwind/mcwind.glsl"

#ifndef MCWR_CLOUD_TRAVEL
#define MCWR_CLOUD_TRAVEL 3.0
#endif

// Blocks after which YOUR noise repeats, 0 to fold it yourself. The drift runs to 65536 and a
// coordinate that size quantises flat long before it wraps.
#ifndef MCWR_CLOUD_PERIOD
#define MCWR_CLOUD_PERIOD 0
#endif

// FOUR wind evaluations. Once per cloud or every Nth step, never per march step.
#ifndef MCWR_CLOUD_GRADIENT
#define MCWR_CLOUD_GRADIENT 1
#endif

struct mcwrCloudRay {
    vec3  drift;
    float t;
};

struct mcwrCloudAir {
    vec3  wind;
    float lift;
    float div;
    float tilt;
    float cell;
};

mcwrCloudRay GetCloudRay() {
    mcwrCloudRay r;
    r.drift = vec3(0.0);
    r.t = 0.0;
#ifdef MCWIND
    r.t = mcw_windPhase;
    // Rigid. Scale this by anything that varies per sample and the noise decorrelates into grey.
    vec3 d = vec3(mcw_windDriftX, 0.0, mcw_windDriftZ) * MCWR_CLOUD_TRAVEL;
    #if MCWR_CLOUD_PERIOD > 0
        d = mod(d, float(MCWR_CLOUD_PERIOD));
    #endif
    r.drift = d;
#endif
    return r;
}

vec3 CloudSamplePos(mcwrCloudRay r, vec3 worldPos) {
    return worldPos - r.drift;
}

mcwrCloudAir GetCloudAir(mcwrCloudRay r, vec3 worldPos) {
    mcwrCloudAir a;
    a.wind = vec3(0.0);
    a.lift = 0.0;
    a.div  = 0.0;
    a.tilt = 0.0;
    a.cell = 0.5;
#ifdef MCWIND
    float gy = mcw_groundHeight(worldPos, cameraPosition);
    a.wind = mcw_windAt(worldPos, r.t, gy, MCW_TURB_WALL_REACH + 1.0, mcw_flowAt(worldPos));
    a.lift = a.wind.y;
    a.cell = mcw_gust(worldPos.xz, r.t);
#endif
    return a;
}

void AddCloudGradient(inout mcwrCloudAir a, vec3 worldPos, float t) {
#if defined MCWIND && MCWR_CLOUD_GRADIENT == 1
    mat3 j = mcw_windJacobian(worldPos, t);
    a.div  = j[0].x + j[1].y + j[2].z;
    a.tilt = length(j[1].xz);
#endif
}

#endif
