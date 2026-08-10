#version 430

// ─────────────────────────────────────────────────────────────────────────────
//  MM_AtmosphericMist  –  Matchbox shader for Autodesk Flame 2025+
// ─────────────────────────────────────────────────────────────────────────────

layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

// Order matches XML declaration order (Page 0 first, then Page 1)
layout(binding = 2) uniform UniformBlock
{
    // Page 0 — Mist Controls
    float WindDir;
    float WindSpeed;
    float Turbulence;
    float TurbulenceSpeed;
    float Height;
    float Density;
    float Scale;
    float CropL;
    float CropR;
    float CropT;
    float CropB;
    float Seed;
    float SoftL;
    float SoftR;
    float SoftT;
    float SoftB;
    float CropLOn;
    float CropROn;
    float CropTOn;
    float CropBOn;
    // Page 1 — Transform
    float PosX;
    float PosY;
    float Rotation;
    float GlobalX;
    float GlobalY;
    float WindZ;
    float GlobalScale;
    // Page 2 — Colour
    float ColourR;
    float ColourG;
    float ColourB;
};

layout(binding = 3) uniform sampler2D front;

// ─────────────────────────────────────────────────────────────────────────────
//  Noise
// ─────────────────────────────────────────────────────────────────────────────

vec2 hash2(vec2 p)
{
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

float gnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = dot(hash2(i + vec2(0.0, 0.0)) * 2.0 - 1.0, f - vec2(0.0, 0.0));
    float b = dot(hash2(i + vec2(1.0, 0.0)) * 2.0 - 1.0, f - vec2(1.0, 0.0));
    float c = dot(hash2(i + vec2(0.0, 1.0)) * 2.0 - 1.0, f - vec2(0.0, 1.0));
    float d = dot(hash2(i + vec2(1.0, 1.0)) * 2.0 - 1.0, f - vec2(1.0, 1.0));
    return 0.5 + 0.5 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p)
{
    float v = 0.0; float a = 0.5; float f = 1.0; float n = 0.0;
    mat2 r = mat2(0.8, -0.6, 0.6, 0.8);
    v += gnoise(p*f)*a; n+=a; a*=0.55; f*=2.0; p=r*p;
    v += gnoise(p*f)*a; n+=a; a*=0.55; f*=2.0; p=r*p;
    v += gnoise(p*f)*a; n+=a; a*=0.55; f*=2.0; p=r*p;
    v += gnoise(p*f)*a; n+=a; a*=0.55; f*=2.0; p=r*p;
    v += gnoise(p*f)*a; n+=a; a*=0.55; f*=2.0; p=r*p;
    v += gnoise(p*f)*a; n+=a;
    return v / n;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Main
// ─────────────────────────────────────────────────────────────────────────────

void main()
{
    const float PI = 3.14159265359;

    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv  = gl_FragCoord.xy / res;

    vec4 src = texture(front, uv);

    // ── Mist transform ────────────────────────────────────────────────────────
    vec2 posUV = vec2(PosX / res.x, PosY / res.y);
    vec2 p = uv - vec2(0.5, 0.5) - posUV;

    float rotRad = -Rotation * PI / 180.0;
    float cosR = cos(rotRad);
    float sinR = sin(rotRad);
    p = vec2(cosR * p.x - sinR * p.y, sinR * p.x + cosR * p.y);

    p = p + vec2(0.5, 0.5);
    p = p - vec2(GlobalX / res.x, GlobalY / res.y);

    float gs = max(GlobalScale, 0.01);
    p = (p - vec2(0.5, 0.5)) / gs + vec2(0.5, 0.5);

    float y = p.y;

    // ── Height mask ───────────────────────────────────────────────────────────
    float heightMask = pow(clamp((Height - y) * 4.0, 0.0, 1.0), 1.5);

    // ── Wind ──────────────────────────────────────────────────────────────────
    float windRad = WindDir * PI / 180.0;
    vec2  drift   = (WindSpeed / 50.0) * vec2(sin(windRad), cos(windRad));

    // ── Noise + domain warp ───────────────────────────────────────────────────
    vec2 seedOffset = vec2(Seed * 127.1, Seed * 311.7);
    vec2 nUV = (vec2(p.x, y) + seedOffset) * Scale + drift * adsk_time;

    float t  = adsk_time * TurbulenceSpeed * 0.003;
    vec2 warp = vec2(
        fbm(nUV + vec2(t * 0.60,  1.70 + t * 0.13)),
        fbm(nUV + vec2(5.20 + t * 0.37, 2.30 - t * 0.71))
    ) * 2.0 - 1.0;
    warp *= Turbulence * Scale * 0.5;

    vec2 warpedUV = nUV + warp;

    // ── Z wind: seamless infinite depth loop ──────────────────────────────────
    // Two overlapping zoom layers crossfade at the reset point.
    // fBm self-similarity makes the transition invisible.
    float zPhase = fract(adsk_time * abs(WindZ) * 0.002);

    // Approaching (WindZ > 0): layers zoom in 1x→2x and 0.5x→1x
    // Receding  (WindZ < 0): layers zoom out 1x→0.5x and 2x→1x
    float zA, zB;
    if (WindZ >= 0.0) {
        zA = 1.0 + zPhase;
        zB = zA * 0.5;
    } else {
        zA = 1.0 / (1.0 + zPhase);
        zB = zA * 2.0;
    }

    // Crossfade: A fades out and B takes over near the reset point
    float fadeA = 1.0 - smoothstep(0.4, 1.0, zPhase);

    // Zoom around screen centre — compute centre in noise space then scale relative to it
    vec2 nCenter = (vec2(0.5, 0.5) + seedOffset) * Scale + drift * adsk_time;
    float noiseA = fbm((warpedUV - nCenter) * zA + nCenter);
    float noiseB = fbm((warpedUV - nCenter) * zB + nCenter);
    float noise  = mix(noiseB, noiseA, fadeA);
    noise = smoothstep(0.35, 0.65, noise);

    // ── Crop mask ─────────────────────────────────────────────────────────────
    float softL = max(SoftL, 0.001);
    float softR = max(SoftR, 0.001);
    float softT = max(SoftT, 0.001);
    float softB = max(SoftB, 0.001);
    float maskL = mix(1.0, smoothstep(CropL,         CropL + softL,         p.x), step(0.5, CropLOn));
    float maskR = mix(1.0, smoothstep(1.0 - CropR,   1.0 - CropR - softR,   p.x), step(0.5, CropROn));
    float maskB = mix(1.0, smoothstep(CropB,         CropB + softB,         p.y), step(0.5, CropBOn));
    float maskT = mix(1.0, smoothstep(1.0 - CropT,   1.0 - CropT - softT,   p.y), step(0.5, CropTOn));
    float cropMask = maskL * maskR * maskB * maskT;

    // ── Composite ─────────────────────────────────────────────────────────────
    float alpha = clamp(noise * heightMask * Density * cropMask, 0.0, 1.0);
    vec3  mist  = vec3(ColourR, ColourG, ColourB);
    vec3 result = mix(src.rgb, mist, alpha);

    fragColor = vec4(result, src.a);
}
