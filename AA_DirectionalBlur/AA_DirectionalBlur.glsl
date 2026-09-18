#version 120
// AA_DirectionalBlur.glsl
// Made by Anthony Augusta. AnthonyAugustaCreations@gmail.com “AA_DirectionalBlur” 
// One Front input + optional Matte. Directional blur with 0°/180° pairing.
// Works on macOS (GLSL 1.20). Uses adsk_result_w/h for resolution.

// ---------------- Inputs ----------------
uniform sampler2D front;
uniform sampler2D matte;   // Optional; if not connected or use_matte=false, ignored.

// ---------------- Result size ----------------
uniform float adsk_result_w, adsk_result_h;

// ---------------- UI Parameters ----------------
uniform float angle_deg;     // 0..360
uniform bool  proportional;  // true = symmetric blur (both directions equal)
uniform float len_pos_px;    // pixels, forward (+) direction
uniform float len_neg_px;    // pixels, backward (−) direction (used when proportional=false)
uniform int   samples;       // total taps across both directions (suggest 32–128)
uniform float center_x;      // signed offset: -1..1 (0 at center, negative=left, positive=right)
uniform float center_y;      // signed offset: -1..1 (0 at center, negative=down, positive=up)
uniform bool  use_center;   // if false, disable center-based bias (uniform blur across frame)
uniform bool  use_matte;     // apply matte constraint if true
uniform bool  swap_lr;     // swap left/right: when true, invert +/− directions

// ---------------- Helpers ----------------
const int MAX_SAMPLES = 256; // hard cap for safety

vec4 readFront(vec2 uv){ return texture2D(front, uv); }
float readMatte(vec2 uv){
    vec4 m = texture2D(matte, uv);
    // Use luminance of matte (works with RGB or single-channel)
    return clamp(dot(m.rgb, vec3(0.2126, 0.7152, 0.0722)), 0.0, 1.0);
}

void main(void)
{
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv  = gl_FragCoord.xy / res;

    // Angle in radians and direction vector in UV units-per-pixel
    float theta = radians(angle_deg);
    vec2 dir_px = vec2(cos(theta), sin(theta));     // in pixels
    vec2 dir_uv = dir_px / res;                     // convert pixels to UV step

    // Effective lengths
    float Lp = max(0.0, len_pos_px);
    float Ln = proportional ? Lp : max(0.0, len_neg_px);

    
    // Center/weighting
    vec2  c      = vec2(0.5) + vec2(center_x, center_y);
    float radial = use_center ? clamp(length(uv - c) * 1.41421356, 0.0, 1.0) : 1.0;
    float Lp_eff = Lp * radial;
    float Ln_eff = Ln * radial;

// Split sample budget proportionally
    float total = max(1e-6, Lp_eff + Ln_eff);
    int np = max(0, int(float(samples) * (Lp_eff / total)));
    int nn = max(0, samples - np);

    // Always include the center sample
    vec4 acc = readFront(uv);
    float wsum = 1.0;

    float lr = swap_lr ? -1.0 : 1.0;

    // Positive direction (+)
    for (int i = 1; i <= MAX_SAMPLES; ++i){
        if (i > np) break;
        float t = float(i) / float(max(1, np));      // 0..1
        vec2  ofs = (lr * dir_uv) * (t * Lp_eff);
        acc += readFront(uv + ofs);
        wsum += 1.0;
    }

    // Negative direction (−)
    for (int i = 1; i <= MAX_SAMPLES; ++i){
        if (i > nn) break;
        float t = float(i) / float(max(1, nn));      // 0..1
        vec2  ofs = (-lr * dir_uv) * (t * Ln_eff);
        acc += readFront(uv + ofs);
        wsum += 1.0;
    }

    vec4 blurred = acc / max(1e-6, wsum);

    // Matte blend (optional)
    if (use_matte){
        float m = readMatte(uv);
        gl_FragColor = mix(readFront(uv), blurred, m);
    } else {
        gl_FragColor = blurred;
    }
}
