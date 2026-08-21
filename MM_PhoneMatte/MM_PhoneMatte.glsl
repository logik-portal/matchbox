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
    // Page 0 Col 4 – Hole Style
    float HoleStyle;
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

// Signed distance to a triangle, given as three points. Distance to each
// edge is measured to the clamped SEGMENT (not the infinite line through
// it), so — unlike an earlier triangle helper in this shader family that
// measured to infinite lines and produced stray streaks far from the
// shape — this stays correct and bounded everywhere, near or far.
float triangleSDF(vec2 p, vec2 a, vec2 b, vec2 c)
{
    vec2 e0 = b - a, e1 = c - b, e2 = a - c;
    vec2 v0 = p - a, v1 = p - b, v2 = p - c;
    vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
    float s = sign(e0.x * e2.y - e0.y * e2.x);
    vec2 d0 = vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x));
    vec2 d1 = vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x));
    vec2 d2 = vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x));
    vec2 d  = min(min(d0, d1), d2);
    return -sqrt(d.x) * sign(d.y);
}

// Proper analytic signed-distance approximation to an ellipse (the cheap
// "scale into circle space" version distorts badly near the ends of the
// major axis) — same technique proven on MM_Playbar's timecode digits.
float ellipseSDF(vec2 p, vec2 r)
{
    vec2  pr = p / r;
    float k1 = length(pr);
    if (k1 < 1e-5) return -min(r.x, r.y);
    vec2  pr2 = p / (r * r);
    float k2 = length(pr2);
    return k1 * (k1 - 1.0) / max(k2, 1e-6);
}

// "Phone lens" notch — traced directly from a reference photo (not
// hand-guessed): a narrow rounded-bottom capsule whose sides flare out to
// the FULL cutout width at the top via two concave fillets, rather than a
// simple circle or a pointed teardrop. hp is relative to the hole's own
// centre (same convention as the other styles); halfHole is half the Hole
// Width/Height. Built from two SDF pieces unioned together: a "top" piece
// (a rectangle spanning the full width, with two ellipses subtracted from
// its corners to carve the concave fillets) and a "bottom" piece (a
// narrower rectangle + an ellipse, forming the rounded-bottom capsule).
// The fillet/cap shapes are ELLIPSES rather than true circles specifically
// so Hole Width and Hole Height can scale their own axis independently —
// a plain circle would have forced any Width change to also change the
// vertical proportions. Each ellipse's radii are chosen so it stays
// exactly tangent to the straight rect edges on both axes (verified
// numerically — no seam at the neck/cap join), and the horizontal
// proportions (neck width ~37% of half-width, fillet width the remainder)
// were fitted against the actual reference image to ~85% IoU.
float phoneNotchSDF(vec2 hp, vec2 halfHole)
{
    float halfW = halfHole.x;
    float h     = halfHole.y * 2.0;

    float neckHalfWidth = halfW * 0.3665;
    float filletRadiusX = halfW * 0.6335;
    float filletRadiusY = h * 0.5626;
    float capRadiusX    = neckHalfWidth;
    float capRadiusY    = h * 0.3255;
    float filletBottomY = filletRadiusY;
    float capStartY     = max(h - capRadiusY, filletBottomY);

    // Local coords with y'=0 at the flat top edge, increasing downward
    // into the shape (matches how the reference was measured/fitted).
    float xq = hp.x;
    float yq = halfHole.y - hp.y;

    // Top piece: full-width rect, corners carved away by two subtracted
    // ellipses (SDF subtraction: max(distRect, -distEllipse)).
    float rectHalfY    = filletBottomY * 0.5;
    float distTopRect  = roundedBoxSDF(vec2(xq, yq - rectHalfY), vec2(halfW, rectHalfY), 0.0);
    float distFilletL  = ellipseSDF(vec2(xq, yq) - vec2(-halfW, filletBottomY), vec2(filletRadiusX, filletRadiusY));
    float distFilletR  = ellipseSDF(vec2(xq, yq) - vec2( halfW, filletBottomY), vec2(filletRadiusX, filletRadiusY));
    float distTop      = max(distTopRect, max(-distFilletL, -distFilletR));

    // Bottom piece: narrow straight-sided rect + rounded-bottom ellipse.
    float neckHalfY      = max((capStartY - filletBottomY) * 0.5, 1e-5);
    float neckCenterY    = filletBottomY + neckHalfY;
    float distNeckRect   = roundedBoxSDF(vec2(xq, yq - neckCenterY), vec2(neckHalfWidth, neckHalfY), 0.0);
    float distCapEllipse = ellipseSDF(vec2(xq, yq) - vec2(0.0, capStartY), vec2(capRadiusX, capRadiusY));
    float distBottom     = min(distNeckRect, distCapEllipse);

    return min(distTop, distBottom);
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

    // ── Camera hole: positioned relative to the phone body's own centre so
    // it moves and scales together with the matte. HolePosX/Y are already
    // in the same aspect-corrected, frame-height-proportion units as aUV
    // (matching Width/Height/CornerRadius), so no extra pixel/resolution
    // conversion is needed here.
    vec2  hp = aUV - vec2(HolePosX, HolePosY);
    vec2  halfHole = vec2(max(HoleWidth, 0.001), max(HoleHeight, 0.001)) * 0.5;
    float distHole;

    int holeStyle = int(clamp(HoleStyle, 0.0, 2.0) + 0.5);

    if (holeStyle == 2)
    {
        distHole = phoneNotchSDF(hp, halfHole);
    }
    else if (holeStyle == 1)
    {
        // Waterdrop/teardrop notch: dominated by a circle (diameter = Hole
        // Width), with only a small, subtle point on top — matching a real
        // phone notch far more closely than a tall sharp cone. The taper's
        // length is capped relative to the circle's own radius (not to
        // Hole Height directly), so pushing Hole Height up thickens the
        // available room for a point without ever stretching it into a
        // spike — Hole Height simply stops mattering past that cap. The
        // triangle's base sits high up the circle (not at its centre) and
        // is narrower than the circle's own width, so it nestles into the
        // circle's curve as a gentle bump rather than a wide seam.
        float r = halfHole.x;
        float circleCenterY = -halfHole.y + r;
        float circleTopY    = circleCenterY + r;
        float desiredExtra  = max(halfHole.y - circleTopY, 0.0);
        float tailLen       = min(desiredExtra, r * 0.4);
        float apexY         = circleTopY + tailLen;
        float baseHalf      = r * 0.5;
        float baseY         = circleCenterY + r * 0.65;
        vec2  apex  = vec2(0.0, apexY);
        vec2  baseL = vec2(-baseHalf, baseY);
        vec2  baseR = vec2( baseHalf, baseY);
        float distCircle   = length(hp - vec2(0.0, circleCenterY)) - r;
        float distTaper    = triangleSDF(hp, apex, baseR, baseL);
        distHole = min(distCircle, distTaper);
    }
    else
    {
        // Rounded-rect / lozenge cutout (the original style).
        float crHole = clamp(HoleRoundness, 0.0, 1.0) * min(halfHole.x, halfHole.y);
        distHole = roundedBoxSDF(hp, halfHole, crHole);
    }

    float holeMask = (1.0 - smoothstep(0.0, soft, distHole)) * step(0.5, HoleOn);

    float alpha = phoneMask * (1.0 - holeMask);

    fragColor = vec4(alpha, alpha, alpha, alpha);
}
