#version 430

layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

layout(binding = 2) uniform UniformBlock
{
    // Page 0 Col 0 – Position
    float PosX;
    float PosY;
    // Page 0 Col 1 – Shape
    float Width;
    float Height;
    float CornerRadius;
    float EdgeSoftness;
    // Page 0 Col 2 – Camera Hole
    float HoleOn;
    // Page 0 Col 3 – Hole Shape
    float HolePosX;
    float HolePosY;
    float HoleWidth;
    float HoleHeight;
    float HoleRoundness;
};

// Signed distance to a rounded rectangle centred at the origin. radius=0
// gives a sharp rect; radius=min(halfSize.x,halfSize.y) gives a full
// stadium/lozenge (pill) shape — used both for the phone body's rounded
// corners and for the camera-hole cutout's lozenge shape, same function.
float roundedBoxSDF(vec2 p, vec2 halfSize, float radius)
{
    vec2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void main()
{
    vec2  res = vec2(adsk_result_w, adsk_result_h);
    vec2  uv  = gl_FragCoord.xy / res;
    float asp = adsk_result_w / adsk_result_h;

    // Aspect-corrected, centred, position-offset coordinates in frame-height
    // units — same convention as the other MM shaders, which is what keeps
    // Width/Height/CornerRadius meaning the same physical proportion of the
    // image regardless of render resolution.
    vec2 posUV = vec2(PosX / res.x, PosY / res.y);
    vec2 p     = uv - vec2(0.5, 0.5) - posUV;
    vec2 aUV   = vec2(p.x * asp, p.y);

    // ── Phone body: rounded rect ───────────────────────────────────────────
    vec2  halfSize = vec2(max(Width, 0.001), max(Height, 0.001)) * 0.5;
    float cr       = clamp(CornerRadius, 0.0, min(halfSize.x, halfSize.y));
    float soft     = max(EdgeSoftness, 0.0001);
    float distBody = roundedBoxSDF(aUV, halfSize, cr);
    float phoneMask = 1.0 - smoothstep(0.0, soft, distBody);

    // ── Camera hole: lozenge/pill cutout, positioned relative to the phone
    // body's own centre so it moves and scales together with the matte.
    // HolePosX/Y are already in the same aspect-corrected, frame-height-
    // proportion units as aUV (matching Width/Height/CornerRadius), so no
    // extra pixel/resolution conversion is needed here.
    vec2  hp = aUV - vec2(HolePosX, HolePosY);
    vec2  halfHole   = vec2(max(HoleWidth, 0.001), max(HoleHeight, 0.001)) * 0.5;
    float crHole     = clamp(HoleRoundness, 0.0, 1.0) * min(halfHole.x, halfHole.y);
    float distHole   = roundedBoxSDF(hp, halfHole, crHole);
    float holeMask   = (1.0 - smoothstep(0.0, soft, distHole)) * step(0.5, HoleOn);

    float alpha = phoneMask * (1.0 - holeMask);

    fragColor = vec4(alpha, alpha, alpha, alpha);
}
