#version 430

layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

layout(binding = 2) uniform UniformBlock
{
    // Page 0 Col 0 – Shape
    float Density;
    float Size;
    float SizeVariation;
    float WindAngle;
    float GustStrength;
    // Page 0 Col 1 – Turbulence
    float GustSpeed;
    float SwayAmount;
    float SwayScale;
    float SwirlAmount;
    float ClusterAmount;
    // Page 0 Col 2 – Sparkle
    float FlurryAmount;
    float PatchScale;
    float SparkleAmount;
    float SparkleSharpness;
    float SparkleSpeed;
    // Page 1 Col 0 – Speed
    float FGSpeed;
    float MidSpeed;
    float BGSpeed;
    float GlobalSpeed;
    // Page 1 Col 1 – Enable
    float SnowEnable;
    float FGEnable;
    float MidEnable;
    float BGEnable;
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
    // Page 4 Col 0 – Light Source
    float LightX;
    float LightY;
    float LightRadius;
    float LightFalloff;
    // Page 4 Col 1 – Light Look
    float LightIntensity;
    float ShowLight;
};

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(dot(i,                vec2(127.1, 311.7))) * 43758.5453);
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

// Round soft flakes, drifting with a lateral sway on top of a straight fall —
// SwayAmount/SwayScale/SparkleAmount/SparkleSharpness/SparkleSpeed are read
// directly as uniforms (no need to grow this function's parameter list).
float snowLayer(vec2 aUV, float t, float speed, float density,
                float windAng, float cell, float radius)
{
    vec2 dir  = vec2(sin(windAng), -cos(windAng));
    vec2 perp = vec2(cos(windAng),  sin(windAng));
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

        float rndB  = hash21(nci + vec2(4.1, 7.9));
        float rndS  = hash21(nci + vec2(2.3, 11.7));
        float rndPh = hash21(nci + vec2(7.3, 2.1));

        // Lateral sway, coherent over blocks sized by SwayScale so nearby
        // flakes drift together in loose gusts rather than independently.
        vec2  block   = floor(nci / max(SwayScale, 0.05));
        float phase   = hash21(block + vec2(9.7, 3.3)) * 6.2832;
        float swayFreq = 0.9 + rndPh * 0.6;
        float lateral  = sin(t * swayFreq + phase) * SwayAmount * cell * 1.6;

        vec2  dropOff = (rnd - 0.5) * 0.8;
        vec2  d       = (ncf - (dropOff + 0.5)) * cell - perp * lateral;
        float dist    = length(d);

        float flakeR = radius * mix(1.0 - SizeVariation * 0.6, 1.0 + SizeVariation * 0.6, rndS);
        float core   = exp(-dist / max(flakeR, 1e-6));

        // Occasional sparkle glint, timed independently per flake.
        float twinkle = pow(max(sin(t * SparkleSpeed * (0.7 + rndPh) + phase), 0.0),
                            max(SparkleSharpness, 0.5)) * SparkleAmount;

        float contrib = core * (0.5 + 0.5 * rndB) * (1.0 + twinkle * 2.2);
        // Screen-blend overlapping flakes instead of max(): max() creates a
        // hard visible seam wherever one flake's field overtakes a neighbour's
        // (very noticeable at cell-grid boundaries); screen blend combines
        // them smoothly and looks like light genuinely accumulating.
        res = 1.0 - (1.0 - res) * (1.0 - clamp(contrib, 0.0, 1.0));
    }
    return clamp(res, 0.0, 1.0);
}

// FG-only variant: irregular lumpy flakes instead of perfectly round dots.
// Deliberately a standalone copy of snowLayer rather than adding a switch
// parameter to it — keeps the proven Mid/BG/Flurry function untouched and
// isolates any risk from this new shape math to the foreground layer alone.
// Shape is faked cheaply by wobbling the distance field with noise sampled
// around a unit circle (continuous, no seam) rather than angular harmonics —
// harmonics produce a symmetric N-pointed star, this reads as an irregular
// asymmetric lump instead.
float snowLayerFG(vec2 aUV, float t, float speed, float density,
                  float windAng, float cell, float radius)
{
    vec2 dir  = vec2(sin(windAng), -cos(windAng));
    vec2 perp = vec2(cos(windAng),  sin(windAng));
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

        float rndB    = hash21(nci + vec2(4.1, 7.9));
        float rndS    = hash21(nci + vec2(2.3, 11.7));
        float rndPh   = hash21(nci + vec2(7.3, 2.1));
        float rndProA = hash21(nci + vec2(6.1, 9.4));
        float rndProP = hash21(nci + vec2(11.3, 4.7));
        vec2  seedOff = hash22(nci + vec2(5.9, 8.4)) * 40.0;

        vec2  block    = floor(nci / max(SwayScale, 0.05));
        float phase    = hash21(block + vec2(9.7, 3.3)) * 6.2832;
        float swayFreq = 0.9 + rndPh * 0.6;
        float lateral  = sin(t * swayFreq + phase) * SwayAmount * cell * 1.6;

        vec2  dropOff = (rnd - 0.5) * 0.8;
        vec2  d       = (ncf - (dropOff + 0.5)) * cell - perp * lateral;

        // Irregular outline: two octaves of noise sampled around a unit
        // circle (seamless, no angle-wrap seam, non-repeating per flake via
        // seedOff) for a jagged lumpy edge, plus one single-direction bulge
        // (random phase/strength per flake) for the asymmetric "protrusion"
        // look from the reference — a lone bump, not a symmetric star since
        // each flake only gets one, in its own random direction.
        float distRaw = length(d);
        vec2  dn      = distRaw > 1e-6 ? d / distRaw : vec2(1.0, 0.0);
        float ang     = atan(d.y, d.x);
        float w1      = vnoise(dn * 2.2 + seedOff) * 2.0 - 1.0;
        float w2      = vnoise(dn * 4.7 + seedOff * 1.7 + vec2(13.0, 5.0)) * 2.0 - 1.0;
        float bulge   = (0.15 + 0.20 * rndProA) * cos(ang + rndProP * 6.2832);
        float lobe    = 1.0 + 0.16 * w1 + 0.08 * w2 + bulge;
        float dist    = distRaw / max(lobe, 0.5);

        float flakeR = radius * mix(1.0 - SizeVariation * 0.6, 1.0 + SizeVariation * 0.6, rndS);

        // Crisp boundary (narrow smoothstep band), not a soft exponential
        // glow — this is what actually reads as a solid irregular chunk of
        // ice like the reference, rather than a blurry circle.
        float edgeBand = max(flakeR * 0.18, 1e-4);
        float core     = smoothstep(flakeR, flakeR - edgeBand, dist);
        // gentle interior shading so it isn't perfectly flat
        core *= mix(0.8, 1.0, clamp(1.0 - dist / max(flakeR, 1e-6), 0.0, 1.0));

        float twinkle = pow(max(sin(t * SparkleSpeed * (0.7 + rndPh) + phase), 0.0),
                            max(SparkleSharpness, 0.5)) * SparkleAmount;

        float contrib = core * (0.5 + 0.5 * rndB) * (1.0 + twinkle * 2.2);
        // Screen-blend instead of max() — same seam-artifact fix as snowLayer,
        // and gives the "flakes glow through each other" look on overlap.
        res = 1.0 - (1.0 - res) * (1.0 - clamp(contrib, 0.0, 1.0));
    }
    return clamp(res, 0.0, 1.0);
}

void main()
{
    vec2  res = vec2(adsk_result_w, adsk_result_h);
    vec2  uv  = gl_FragCoord.xy / res;
    float asp = adsk_result_w / adsk_result_h;
    // Wrap time to keep sin()/noise precision stable on very long timelines,
    // then apply GlobalSpeed so everything (fall, sway, sparkle, clustering,
    // patchiness) speeds up or slows down together as one coherent motion.
    // Wrap period is large (100,000) so it's never hit in normal shot lengths
    // — a small period (e.g. 100) causes a visible hitch every time it wraps.
    float t = mod(adsk_time, 100000.0) * clamp(GlobalSpeed, 0.02, 5.0);

    // ── Transform: position, rotation, global transform, global scale ────────
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

    vec2 aUV = vec2(tp.x * asp, tp.y);

    float baseAng = WindAngle * 0.017453;
    float gust    = (sin(t * GustSpeed * 0.41) * 0.65
                  + sin(t * GustSpeed * 1.13 + 1.9) * 0.35)
                  * GustStrength * 0.017453;
    float windAng = baseAng + gust;

    float radius = Size * 0.006;

    float fg  = snowLayerFG(aUV, t, FGSpeed, Density * 0.55, windAng, 0.050, radius * 1.6) * step(0.5, FGEnable);
    float mid = snowLayer(aUV, t, MidSpeed, Density * 0.70, windAng, 0.032, radius * 1.0)  * step(0.5, MidEnable);
    float bg  = snowLayer(aUV, t, BGSpeed,  Density * 0.85, windAng, 0.020, radius * 0.6)  * step(0.5, BGEnable);

    // Flurry: fourth micro layer of tiny fast haze flakes, same function.
    float fly = snowLayer(aUV, t, BGSpeed * 1.4, Density * 0.95, windAng, 0.010, radius * 0.32)
              * clamp(FlurryAmount, 0.0, 1.0);

    // Clustering: single noise sample per pixel, floored so gaps never go
    // fully black — big drifting curtains of heavier/lighter snowfall.
    vec2  cp     = tp * 1.2 + vec2(0.0, t * 0.04);
    float cn     = vnoise(cp) * 0.6 + vnoise(cp * 2.3 + vec2(3.1, 7.4)) * 0.4;
    float cshape = smoothstep(0.25, 0.75, cn);
    float cluster = mix(1.0, max(cshape, 0.10), clamp(ClusterAmount, 0.0, 1.0));

    // Patchiness: independent slow brightness field, own scale/speed.
    float patchScale = max(PatchScale, 0.05);
    vec2  pp        = tp * patchScale + vec2(0.0, t * 0.025);
    float pshape    = smoothstep(0.20, 0.80, vnoise(pp));
    float patchMult = mix(1.0, max(pshape, 0.25), clamp(SwirlAmount, 0.0, 1.0));

    // Crop mask, same convention as Transform/Crop pages on MM_Rain.
    float softL = max(SoftL, 0.001);
    float softR = max(SoftR, 0.001);
    float softT = max(SoftT, 0.001);
    float softB = max(SoftB, 0.001);
    float maskL = mix(1.0, smoothstep(CropL,       CropL + softL,       tp.x), step(0.5, CropLOn));
    float maskR = mix(1.0, smoothstep(1.0 - CropR, 1.0 - CropR - softR, tp.x), step(0.5, CropROn));
    float maskB = mix(1.0, smoothstep(CropB,       CropB + softB,       tp.y), step(0.5, CropBOn));
    float maskT = mix(1.0, smoothstep(1.0 - CropT, 1.0 - CropT - softT, tp.y), step(0.5, CropTOn));
    float cropMask = maskL * maskR * maskB * maskT;

    vec3 col = (vec3(1.00, 1.00, 1.00) * clamp(fg,  0.0, 1.0)
             +  vec3(0.90, 0.93, 0.98) * clamp(mid, 0.0, 1.0)
             +  vec3(0.75, 0.80, 0.90) * clamp(bg,  0.0, 1.0)
             +  vec3(0.65, 0.70, 0.82) * clamp(fly, 0.0, 1.0)) * cluster * patchMult * cropMask;

    float alpha = clamp((fg * 0.95 + mid * 0.80 + bg * 0.60 + fly * 0.40) * cluster * patchMult * cropMask, 0.0, 1.0);

    // Light Source: a point (e.g. a street light) that brightens nearby snow —
    // pure radial brightness boost on the final colour/alpha, no position or
    // motion warping involved, so none of the grid-coherence/lensing issues
    // that ruled out a moving wind vent apply here — this is safe.
    // Deliberately measured against the RAW screen position (aspect-corrected
    // "uv", not the post-Transform "aUV") — the light has its own independent
    // Light X/Y and must stay fixed in the frame regardless of Position,
    // Rotation, or Global Transform applied to the snow field itself.
    vec2  lightScreenUV = vec2(uv.x * asp, uv.y);
    vec2  lightPos       = vec2(LightX * asp, LightY);
    float distToLight    = length(lightScreenUV - lightPos);
    float lightOuter  = LightRadius + max(LightFalloff, 0.001);
    float lightMask   = 1.0 - smoothstep(LightRadius, lightOuter, distToLight);
    float lightBoost  = 1.0 + max(LightIntensity, 0.0) * lightMask;

    col   *= lightBoost;
    alpha  = clamp(alpha * lightBoost, 0.0, 1.0);

    float snowOn = step(0.5, SnowEnable);
    col   *= snowOn;
    alpha *= snowOn;

    // Light Source setup aid: radius/falloff rings + crosshair, drawn last so
    // they're always visible while dialing in position. Turn off before final
    // render.
    if (ShowLight > 0.5)
    {
        float lineW  = 0.0022;
        float ringR  = 1.0 - smoothstep(0.0, lineW, abs(distToLight - LightRadius));
        float ringO  = 1.0 - smoothstep(0.0, lineW, abs(distToLight - lightOuter));
        vec2  dC     = lightScreenUV - lightPos;
        float cross  = float(abs(dC.y) < lineW && abs(dC.x) < 0.02)
                     + float(abs(dC.x) < lineW && abs(dC.y) < 0.02);
        float showMask = clamp(ringR + ringO + cross, 0.0, 1.0);
        col   = mix(col, vec3(1.0, 0.82, 0.15), showMask);
        alpha = max(alpha, showMask);
    }

    fragColor = vec4(col, alpha);
}
