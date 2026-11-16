// sv_Depth_Temporal_Stabilizer
// Copyright (c) 2026 Sinan Vural. MIT License.
// https://github.com/SinanVural1/matchbox/tree/main/shaders/sv_Depth_Temporal_Stabilizer

// ---------------------------------------------------------------------------
// Depth Map Temporal Stabilizer
// Two-point affine (scale + shift) stabilization for relative depth models
// such as DepthAnything V2 running in the ML Inference node.
//
// Model:      d_t(x) = a_t * d_true(x) + b_t     (affine-invariant output)
// Solve:      two tracked samples fully determine a_t and b_t per frame.
// Correction: out = (d - s1) * (T1 - T2) / (s1 - s2) + T1
//
// Feed this the RAW model output, before any 1/z inversion, gamma or
// falloff curve. The affine relationship only holds in native disparity space.
// ---------------------------------------------------------------------------

uniform float adsk_result_w;
uniform float adsk_result_h;

uniform sampler2D front;
uniform sampler2D back;        // Original image. Never read: it exists so F2 can show it

// Sample positions. On-screen axes report normalized 0-1; pasted Action
// tracker curves are in pixels from image centre, so centerOrigin says which.
uniform vec2 point1;
uniform vec2 point2;
uniform bool centerOrigin;     // Action tracker data: pixels, origin at image centre

// Target values: what the depth SHOULD read at each point. Sample these
// off your reference frame with the colour picker and type them in.
uniform float target1;
uniform float target2;

uniform float sampleRadius;    // Averaging radius in pixels
uniform float minSep;          // Fraction of sample depth below which the solve fades
uniform bool  showMarkers;     // Draw the sample footprints

// ---- Output range selection ----
uniform int   rangeMode;       // 0 distance | 1 near/far | 2 range
uniform float nearVal;
uniform float farVal;
uniform float nfFalloff;
uniform float rangeCenter;
uniform float rangeWidth;
uniform float rangeFalloff;

// Distance : pass the stabilized depth through untouched.
// Near/Far : normalize the window between Near and Far to 0-1, shaped by
//            an exponent. Falloff 1.0 is a straight ramp, above 1 pushes
//            detail toward Far, below 1 toward Near.
// Range    : white at the selected depth, holding across Range, with
//            Falloff softening both edges. Useful straight as a matte.
float applyRange(float v)
{
    if (rangeMode == 1) {
        float span = farVal - nearVal;
        float sgn  = (span < 0.0) ? -1.0 : 1.0;
        span = sgn * max(abs(span), 0.00001);

        float t = clamp((v - nearVal) / span, 0.0, 1.0);
        return pow(t, max(nfFalloff, 0.001));
    }
    else if (rangeMode == 2) {
        float halfW = max(rangeWidth, 0.0) * 0.5;
        float fo    = max(rangeFalloff, 0.00001);
        float dist  = abs(v - rangeCenter);
        return 1.0 - smoothstep(halfW, halfW + fo, dist);
    }
    return v;
}

// 5x5 box average spanning +/- sampleRadius. Kills model noise without
// shifting the reading on a flat surface. Relies on GL_LINEAR on the input:
// with GL_NEAREST every tap snaps to a texel at once, so sub-pixel tracker
// motion would make the reading step over time.
float sampleDepth(vec2 puv)
{
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 stepUV = vec2(sampleRadius * 0.5) / res;
    float acc = 0.0;

    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            vec2 o = vec2(float(i), float(j)) * stepUV;
            acc += texture2D(front, clamp(puv + o, 0.0, 1.0)).r;
        }
    }
    return acc / 25.0;
}

void main(void)
{
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv  = gl_FragCoord.xy / res;

    vec2 p1 = point1;
    vec2 p2 = point2;

    // Bring everything into bottom-left pixel space.
    if (centerOrigin) {
        p1 += res * 0.5;
        p2 += res * 0.5;
    }
    else {
        p1 *= res;
        p2 *= res;
    }

    vec2 uv1 = clamp(p1 / res, 0.0, 1.0);
    vec2 uv2 = clamp(p2 / res, 0.0, 1.0);

    float s1 = sampleDepth(uv1);
    float s2 = sampleDepth(uv2);

    // Exact solve while the samples are far enough apart, so swapping the points
    // gives a true inverted map. The limit is a fraction of the samples' own
    // depth because estimator output has no fixed scale. Below it the gain fades
    // through zero, so noise swapping s1 and s2 as the points converge passes
    // through a flat map rather than snapping straight to an inverted one.
    float den   = s1 - s2;
    float limit = max(minSep * max(abs(s1), abs(s2)), 0.00001);
    float gain  = (target1 - target2) / max(abs(den), limit)
                * clamp(den / limit, -1.0, 1.0);

    float d    = texture2D(front, uv).r;
    float stab = (d - s1) * gain + target1;

    // NaN never equals itself. Fall back to the uncorrected value rather
    // than letting a bad frame flood white.
    if (stab != stab) {
        stab = d;
    }

    // Range selection runs on the corrected depth, after the affine solve.
    stab = applyRange(stab);

    vec3 rgb = vec3(stab);

    if (showMarkers) {
        // Draw the sample footprints so you can confirm the trackers land
        // where you think they do, and that neither straddles a depth edge.
        vec2 pxPos = uv * res;
        float r1 = distance(pxPos, p1);
        float r2 = distance(pxPos, p2);
        float ring = max(sampleRadius, 2.0);

        if (abs(r1 - ring) < 1.5) rgb = vec3(1.0, 0.0, 0.0);
        if (abs(r2 - ring) < 1.5) rgb = vec3(0.0, 1.0, 0.0);
    }

    // MatteProvider sends alpha to the node's matte output, so that output is
    // the inverted result. Taken from stab so the markers never reach it.
    gl_FragColor = vec4(rgb, 1.0 - stab);
}
