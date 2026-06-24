// AB_Halation.glsl
// Halation effect for Autodesk Flame (Matchbox)
//
// Two quality modes selectable via dropdown:
//
// LOW  — fast 8-tap kernel stepping by radius px per tap.
//        Large spread, good for interactive work and previews.
//        May show some dithering at large radii.
//
// HIGH — smooth 48-tap kernel stepping by 2px per tap.
//        Clean smooth gradation, no artifacts.
//        Slower — use for finals.

uniform sampler2D front;
uniform sampler2D matte;

uniform float adsk_result_w;
uniform float adsk_result_h;

uniform float red_radius;
uniform float green_influence;
uniform float strength;
uniform float threshold;

// 0 = Low (fast), 1 = High (quality)
uniform float quality;

// ------------------------------------------------------------------
// Gaussian weight
// ------------------------------------------------------------------
float gaussian(float offset, float sigma) {
    return exp(-(offset * offset) / (2.0 * sigma * sigma));
}

// ------------------------------------------------------------------
// IGN jitter for low quality mode
// ------------------------------------------------------------------
float IGN(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

// ------------------------------------------------------------------
// LOW quality — original 8-tap kernel.
// Fast, large spread. Steps by radius px per tap.
// ------------------------------------------------------------------
float blurChannelLow(sampler2D tex, vec2 uv, vec2 texelSize,
                     float radius, int channel, float thresh) {

    if (radius <= 0.0) return 0.0;

    float sigma     = max(radius * 0.35, 0.001);
    float total     = 0.0;
    float weightSum = 0.0;
    float jitter    = IGN(gl_FragCoord.xy) - 0.5;

    for (int x = -16; x <= 16; x++) {
        for (int y = -16; y <= 16; y++) {
            float fx = float(x) + jitter;
            float fy = float(y) + jitter;

            float wx = gaussian(fx, sigma / texelSize.x);
            float wy = gaussian(fy, sigma / texelSize.y);
            float w  = wx * wy;

            vec2 sampleUV = uv + vec2(fx, fy) * texelSize * radius;
            vec4 s = texture2D(tex, sampleUV);

            float val;
            if (channel == 0)      val = s.r;
            else if (channel == 1) val = s.g;
            else                   val = s.b;

            val = max(val - thresh, 0.0);
            total     += val * w;
            weightSum += w;
        }
    }

    return (weightSum > 0.0) ? total / weightSum : 0.0;
}

// ------------------------------------------------------------------
// HIGH quality — 48-tap kernel with step size scaled to match
// the same physical spread as the low quality kernel.
// Step = radius / 48 * 16 so both kernels reach the same distance.
// Smooth clean gradation with no artifacts.
// ------------------------------------------------------------------
float blurChannelHigh(sampler2D tex, vec2 uv, vec2 texelSize,
                      float radius, int channel, float thresh) {

    if (radius <= 0.0) return 0.0;

    // Step scaled to match low quality spread:
    // Low reaches radius * 16 px total, so high step = radius * 16 / 48
    float stepSize  = max(radius * 16.0 / 48.0, 0.5);
    float sigma     = max(radius * 0.35, 0.001);
    float total     = 0.0;
    float weightSum = 0.0;

    for (int x = -48; x <= 48; x++) {
        for (int y = -48; y <= 48; y++) {
            float fx = float(x);
            float fy = float(y);

            float wx = gaussian(fx, sigma / texelSize.x);
            float wy = gaussian(fy, sigma / texelSize.y);
            float w  = wx * wy;

            if (w < 0.0001) continue;

            vec2 sampleUV = uv + vec2(fx, fy) * texelSize * stepSize;
            vec4 s = texture2D(tex, sampleUV);

            float val;
            if (channel == 0)      val = s.r;
            else if (channel == 1) val = s.g;
            else                   val = s.b;

            val = max(val - thresh, 0.0);
            total     += val * w;
            weightSum += w;
        }
    }

    return (weightSum > 0.0) ? total / weightSum : 0.0;
}

// ------------------------------------------------------------------
// Main
// ------------------------------------------------------------------
void main() {
    vec2 uv    = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 texel = 1.0 / vec2(adsk_result_w, adsk_result_h);

    vec4  src      = texture2D(front, uv);
    float alpha    = texture2D(matte, uv).r;
    vec3  original = src.rgb;

    float r_radius = red_radius;
    float g_radius = red_radius * green_influence;

    float blurR, blurG;

    if (quality < 0.5) {
        // Low quality — fast
        blurR = blurChannelLow(front, uv, texel, r_radius, 0, threshold);
        blurG = blurChannelLow(front, uv, texel, g_radius, 1, threshold);
    } else {
        // High quality — smooth
        blurR = blurChannelHigh(front, uv, texel, r_radius, 0, threshold);
        blurG = blurChannelHigh(front, uv, texel, g_radius, 1, threshold);
    }

    blurG *= green_influence * green_influence * green_influence;

    vec3 halo   = vec3(blurR, blurG, 0.0) * strength;
    vec3 result = original + halo;

    gl_FragColor = vec4(result, alpha);
}
