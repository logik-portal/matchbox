#version 430

layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

layout(binding = 2) uniform UniformBlock
{
    float Density;
    float Length;
    float Width;
    float WindAngle;
    float GustStrength;
    float GustSpeed;
    float TurbulenceAmount;
    float TurbulenceScale;
    float SwirlAmount;
    float ClusterAmount;
    float MistAmount;
    float MistScale;
    float LightAngle;
    float LightIntensity;
    float GlintSharpness;
    float FGSpeed;
    float MidSpeed;
    float BGSpeed;
    // Page 1 Col 1 – Enable
    float RainEnable;
    float FGEnable;
    float MidEnable;
    float BGEnable;
    // Page 1 Col 2 – Density
    float FGDensity;
    float MidDensity;
    float BGDensity;
    // Page 2 – Transform
    float PosX;
    float PosY;
    float Rotation;
    float GlobalX;
    float GlobalY;
    float GlobalScale;
    // Page 3 – Crop
    float CropL;
    float CropR;
    float CropT;
    float CropB;
    float SoftL;
    float SoftR;
    float SoftT;
    float SoftB;
    float CropLOn;
    float CropROn;
    float CropTOn;
    float CropBOn;
    // Page 4 Col 0 – Occlusion (mattes are separate texture inputs)
    // Page 4 Col 1 – Defocus
    float FGDefocus;
    float MidDefocus;
    float BGDefocus;
    float MistDefocus;
    float MistEnable;
};

// "front" doubles as an optional background plate — unconnected (NoInput
// defaults to black) it reproduces the old pure-generator behaviour exactly
// (rain added onto nothing), connected it composites the rain directly onto
// the plate. Occlusion mattes: white = hide rain there (object in front).
layout(binding = 3) uniform sampler2D front;
layout(binding = 4) uniform sampler2D matteFG;
layout(binding = 5) uniform sampler2D matteMid;
layout(binding = 6) uniform sampler2D matteBG;

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(dot(i,               vec2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0,0.0),vec2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0,1.0),vec2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0,1.0),vec2(127.1, 311.7))) * 43758.5453);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float hash21(vec2 p)
{
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec2 hash22(vec2 p)
{
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

float particleLayer(vec2 aUV, float t, float speed, float density,
                    float windAng, float scatter,
                    float cell, float radius, float halfLen)
{
    vec2 dir  = vec2(sin(windAng), -cos(windAng));
    vec2 ci   = floor((aUV - dir * t * speed) / cell);
    vec2 cf   = fract((aUV - dir * t * speed) / cell);
    float res = 0.0;

    for (int oy = -1; oy <= 1; oy++)
    for (int ox = -1; ox <= 1; ox++)
    {
        vec2  nci  = ci + vec2(float(ox), float(oy));
        vec2  ncf  = cf - vec2(float(ox), float(oy));
        vec2  rnd  = hash22(nci);
        if (rnd.x > density) continue;

        float rndB = hash21(nci + vec2(4.1, 7.9));
        float rndL = hash21(nci + vec2(2.3, 11.7));
        // Per-drop angle variety, coherent over blocks of cells sized by
        // TurbulenceScale — low = broad sweeps of similarly-angled drops,
        // high = fine chaotic variety between neighbours. TurbulenceScale
        // is a uniform, read directly here (no need to pass through).
        vec2  block = floor(nci / max(TurbulenceScale, 0.05));
        float rndA  = hash21(block + vec2(7.3, 2.1));

        // Per-drop angle variety — each drop still falls perfectly straight,
        // just a slightly different angle from its neighbours. Not bending.
        float dAng = windAng + (rndA * 2.0 - 1.0) * scatter * 0.2094;
        vec2  ddir = vec2(sin(dAng), -cos(dAng));
        vec2  dprp = vec2(cos(dAng),  sin(dAng));

        vec2  d    = (ncf - (rnd - 0.5) * 0.8 - 0.5) * cell;
        float dA   = dot(d, ddir);
        float dP   = dot(d, dprp);
        float edge = max(abs(dA) - halfLen * (0.6 + 0.65 * rndL), 0.0);
        float dist = sqrt(edge * edge + dP * dP);

        // Per-drop glint: THIS drop's own fall angle vs the light direction.
        // Rotating LightAngle changes which drops catch the light, not just
        // the overall brightness — gives a real directional feel.
        float lightRad = LightAngle * 0.017453;
        vec2  lDir     = vec2(sin(lightRad), cos(lightRad));
        float dSpec    = pow(abs(dot(ddir, lDir)), max(GlintSharpness, 0.5)) * LightIntensity;

        res = max(res, exp(-dist / max(radius, 1e-6)) * (0.4 + 0.6 * rndB) * (1.0 + dSpec * 1.8));
    }
    return clamp(res, 0.0, 1.0);
}

// Genuine soft-focus blur, not just a bigger/softer drop: re-evaluates the
// whole layer at several nearby positions and blends them. Costs N extra
// full evaluations of particleLayer, so it's skipped entirely (single
// evaluation) whenever defocusPix is ~0 — the common case.
//
// 9 taps arranged in a circle (not a diamond) with Gaussian-style falloff
// weighting — this reads as a smooth, bokeh-like soft focus rather than the
// visible 4-armed pattern a small diamond/box average leaves behind.
float defocusLayer(vec2 aUV, float t, float speed, float density,
                   float windAng, float scatter, float cell, float radius,
                   float halfLen, float defocusPix)
{
    if (defocusPix < 1e-4)
        return particleLayer(aUV, t, speed, density, windAng, scatter, cell, radius, halfLen);

    const int   TAPS  = 9;
    const float TWOPI = 6.2831853;

    float sum = particleLayer(aUV, t, speed, density, windAng, scatter, cell, radius, halfLen);
    float wsum = 1.0;

    for (int i = 0; i < TAPS; i++)
    {
        float ang    = TWOPI * float(i) / float(TAPS);
        float ringR  = 0.55 + 0.45 * fract(float(i) * 0.61803398875); // two loose rings, not one ring
        vec2  offset = vec2(cos(ang), sin(ang)) * ringR * defocusPix;
        float w      = exp(-1.2 * ringR * ringR); // Gaussian-style falloff by ring radius

        sum  += particleLayer(aUV + offset, t, speed, density, windAng, scatter, cell, radius, halfLen) * w;
        wsum += w;
    }
    return sum / wsum;
}

void main()
{
    vec2  res = vec2(adsk_result_w, adsk_result_h);
    vec2  uv  = gl_FragCoord.xy / res;
    float asp = adsk_result_w / adsk_result_h;
    // adsk_time can grow large on a long timeline; sin()/noise lose precision
    // at large arguments. Wrap to a bounded range to keep precision stable —
    // period is large (100,000) so it's never hit in normal shot lengths, since
    // a small period (e.g. 100) causes a visible hitch every time it wraps.
    float t   = mod(adsk_time, 100000.0);

    // ── Transform: position, rotation, global transform, global scale ────────
    // Same convention as MM_AtmosphericMist — PosX/Y and GlobalX/Y are in
    // pixels matching Flame's axis, Rotation in degrees, GlobalScale zooms
    // around frame centre. Everything downstream reads from tp, not raw uv,
    // so the whole rain field (particles + clustering + patchiness) moves
    // together as one layer.
    vec2 posUV = vec2(PosX / res.x, PosY / res.y);
    vec2 tp    = uv - vec2(0.5, 0.5) - posUV;

    float rotRad = -Rotation * 0.017453;
    float cosR   = cos(rotRad);
    float sinR   = sin(rotRad);
    tp = vec2(cosR * tp.x - sinR * tp.y, sinR * tp.x + cosR * tp.y);

    tp = tp + vec2(0.5, 0.5);
    tp = tp - vec2(GlobalX / res.x, GlobalY / res.y);

    float gScale = max(GlobalScale, 0.01);
    tp = (tp - vec2(0.5, 0.5)) / gScale + vec2(0.5, 0.5);

    vec2  aUV = vec2(tp.x * asp, tp.y);

    float baseAng = WindAngle * 0.017453;
    float gust    = (sin(t * GustSpeed * 0.41) * 0.65
                  + sin(t * GustSpeed * 1.13 + 1.9) * 0.35)
                  * GustStrength * 0.017453;
    float windAng = baseAng + gust;
    float scatter = clamp(TurbulenceAmount, 0.0, 1.0);

    float radius  = Width * 0.005;
    float hlenFG  = Length * 0.030;
    float hlenMid = Length * 0.020;
    float hlenBG  = Length * 0.013;

    // Occlusion mattes sampled in raw screen space (uv, not the transformed
    // aUV/tp) — they describe where objects sit in the actual composited
    // frame, so they must stay fixed regardless of Position/Rotation/Global
    // Transform applied to the rain field itself. White = hide rain there.
    float fgOcc  = 1.0 - clamp(dot(texture(matteFG,  uv).rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
    float midOcc = 1.0 - clamp(dot(texture(matteMid, uv).rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
    float bgOcc  = 1.0 - clamp(dot(texture(matteBG,  uv).rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    // Defocus in pixels-of-UV-offset — small range, each layer independent.
    float fgBlur  = max(FGDefocus,  0.0) * 0.01;
    float midBlur = max(MidDefocus, 0.0) * 0.01;
    float bgBlur  = max(BGDefocus,  0.0) * 0.01;

    // Density multipliers beyond 1.0 can't add more drops through probability
    // alone (a cell either has a drop or doesn't - past 100% occupancy,
    // raising the number further does nothing). For genuinely heavier rain,
    // extra multiplier beyond 1.0 instead shrinks the cell size, packing more
    // possible drop slots into the same area, while the probability itself
    // stays saturated at 1.0.
    float fgMult  = clamp(FGDensity,  0.0, 3.0);
    float midMult = clamp(MidDensity, 0.0, 3.0);
    float bgMult  = clamp(BGDensity,  0.0, 3.0);

    float fgCell  = 0.042 / sqrt(max(fgMult,  1.0));
    float midCell = 0.026 / sqrt(max(midMult, 1.0));
    float bgCell  = 0.015 / sqrt(max(bgMult,  1.0));

    float fgDens  = clamp(Density * 0.75 * min(fgMult,  1.0), 0.0, 1.0);
    float midDens = clamp(Density * 0.85 * min(midMult, 1.0), 0.0, 1.0);
    float bgDens  = clamp(Density * 0.92 * min(bgMult,  1.0), 0.0, 1.0);

    float fg  = defocusLayer(aUV, t, FGSpeed,  fgDens,  windAng, scatter,       fgCell,  radius * 1.4,  hlenFG,  fgBlur)  * step(0.5, FGEnable)  * fgOcc;
    float mid = defocusLayer(aUV, t, MidSpeed, midDens, windAng, scatter * 0.7, midCell, radius * 0.85, hlenMid, midBlur) * step(0.5, MidEnable) * midOcc;
    float bg  = defocusLayer(aUV, t, BGSpeed,  bgDens,  windAng, scatter * 0.4, bgCell,  radius * 0.55, hlenBG,  bgBlur)  * step(0.5, BGEnable)  * bgOcc;

    // Mist: fourth micro layer of fine spray/haze particles, same function,
    // small cell/radius, gated by MistAmount and its own on/off toggle.
    float mistBlur = max(MistDefocus, 0.0) * 0.01;
    float mic = defocusLayer(aUV, t, BGSpeed * 0.5, Density * 0.98, windAng,
                             scatter * 0.3, 0.009, radius * 0.45, Length * 0.006, mistBlur)
              * clamp(MistAmount, 0.0, 1.0) * 2.2 * step(0.5, MistEnable);

    // Clustering: single fbm-free noise sample per pixel, floor at 0.08 so gaps
    // read as genuinely dark/sparse while never fully vanishing to true black.
    // Drifts straight down the Y axis at a steady rate — no wind/gust coupling,
    // so the patches pan smoothly instead of wobbling with the gust angle.
    vec2  cp     = tp * 1.2 + vec2(0.0, t * 0.05);
    float cn     = vnoise(cp) * 0.6 + vnoise(cp * 2.3 + vec2(3.1, 7.4)) * 0.4;
    float cshape = smoothstep(0.25, 0.75, cn);
    float cluster = mix(1.0, max(cshape, 0.08), clamp(ClusterAmount, 0.0, 1.0));

    // Patchiness: independent slow-drifting brightness field, single noise
    // sample (cheap) — MistScale controls its size, SwirlAmount its intensity.
    float patchScale = max(MistScale, 0.05);
    vec2  pp       = tp * patchScale + vec2(0.0, t * 0.03);
    float pshape   = smoothstep(0.20, 0.80, vnoise(pp));
    float patchMult = mix(1.0, max(pshape, 0.20), clamp(SwirlAmount, 0.0, 1.0));

    // Crop mask, in the post-transform space so it moves/rotates/scales with
    // the rain field. Each edge independently toggled and feathered.
    float softL = max(SoftL, 0.001);
    float softR = max(SoftR, 0.001);
    float softT = max(SoftT, 0.001);
    float softB = max(SoftB, 0.001);
    float maskL = mix(1.0, smoothstep(CropL,       CropL + softL,       tp.x), step(0.5, CropLOn));
    float maskR = mix(1.0, smoothstep(1.0 - CropR, 1.0 - CropR - softR, tp.x), step(0.5, CropROn));
    float maskB = mix(1.0, smoothstep(CropB,       CropB + softB,       tp.y), step(0.5, CropBOn));
    float maskT = mix(1.0, smoothstep(1.0 - CropT, 1.0 - CropT - softT, tp.y), step(0.5, CropTOn));
    float cropMask = maskL * maskR * maskB * maskT;

    vec3 col = (vec3(0.95, 0.97, 1.00) * clamp(fg,  0.0, 1.0)
             +  vec3(0.72, 0.79, 0.90) * clamp(mid, 0.0, 1.0)
             +  vec3(0.48, 0.54, 0.66) * clamp(bg,  0.0, 1.0)
             +  vec3(0.55, 0.60, 0.70) * clamp(mic, 0.0, 1.0)) * cluster * patchMult * cropMask;

    float alpha = clamp((fg * 0.95 + mid * 0.75 + bg * 0.55 + mic * 0.60) * cluster * patchMult * cropMask, 0.0, 1.0);

    float rainOn = step(0.5, RainEnable);

    // "front" doubles as an optional background plate. Unconnected it
    // defaults to black, so this reproduces the exact old pure-generator
    // behaviour (rain added onto nothing); connected, the rain composites
    // additively straight onto the plate, matching the same Add/Screen look
    // this shader has always been designed around.
    vec3 backCol = texture(front, uv).rgb;
    fragColor = vec4(backCol + col * rainOn, alpha * rainOn);
}
