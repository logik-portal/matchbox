#version 120

/*
**MIT License
**
**Copyright (c) 2018
**
**Permission is hereby granted, free of charge, to any person obtaining a copy
**of this software and associated documentation files (the "Software"), to deal
**in the Software without restriction, including without limitation the rights
**to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
**copies of the Software, and to permit persons to whom the Software is
**furnished to do so, subject to the following conditions:
**
**The above copyright notice and this permission notice shall be included in all
**copies or substantial portions of the Software.
**
**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
**IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
**FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
**AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
**LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
**OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
**SOFTWARE.
*/

uniform bool adsk_degrade;
uniform float adsk_front_frameratio, adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass1, front, matte;
uniform bool distortion_correction;
uniform float distortion_a;
uniform float distortion_b;
uniform float distortion_c;
uniform float distortion_anamorphic;
uniform vec2 distortion_shift;
uniform bool uv_output;
uniform int antialias_samples;

vec2 h;
vec2 cos_phi_cos_theta;
vec2 sin_phi_sin_theta;
mat2 rot_m;
vec2 trans_v;
mat2 trans_m;

vec2 get_coords(vec2 coords) {
    vec2 r, d;
    float r2;
    coords /= vec2(adsk_result_w, adsk_result_h);
    coords -= .5;
    coords *= vec2(adsk_result_frameratio * h.t, h.t);
    coords = rot_m * coords;
    coords = (trans_m * coords + trans_v) / (cos_phi_cos_theta.t * (sin_phi_sin_theta.s * coords.x + cos_phi_cos_theta.s) + sin_phi_sin_theta.t * coords.y);
    if (distortion_correction) {
        d = vec2(distortion_shift.x / distortion_anamorphic, distortion_shift.y);
        coords /= vec2(distortion_anamorphic * h.s, h.s);
        r = coords - d;
        r2 = dot(r, r) / (.25 * adsk_front_frameratio * adsk_front_frameratio / (distortion_anamorphic * distortion_anamorphic) + .25);
        coords = d + r * (1. + distortion_a * r2 + distortion_b * r2 * r2 + distortion_c * r2 * r2 * r2);
        coords.x *= distortion_anamorphic / adsk_front_frameratio;
    }
    else
        coords /= vec2(adsk_front_frameratio * h.s, h.s);
    coords += .5;
    return coords;
}

float get_matte(vec2 coords) {
    if (0. <= coords.x && 0. <= coords.y && coords.x <= 1. && coords.y <= 1.)
        return texture2D(matte, coords).b;
    return 0.;
}

vec4 get_tex(vec2 coords) {
    if (0. <= coords.x && 0. <= coords.y && coords.x <= 1. && coords.y <= 1.)
        return vec4(texture2D(front, coords).rgb, texture2D(matte, coords).b);
    return vec4(0.);
}

#define C_1_4096 .000244140625
#define C_1_1024 .0009765625
#define C_1_256  .00390625
#define C_1_128  .0078125
#define C_1_64   .015625
#define C_1_32   .03125
#define C_1_16   .0625
#define C_1_8    .125
#define C_3_16   .1875
#define C_1_4    .25
#define C_5_16   .3125
#define C_3_8    .375
#define C_7_16   .4375

#define MATTE_O(OFFSET) get_matte(get_coords(gl_FragCoord.xy + OFFSET))

#define TEX_N() get_tex(get_coords(gl_FragCoord.xy))
#define TEX_O(OFFSET) get_tex(get_coords(gl_FragCoord.xy + OFFSET))

void main(void) {
    int i, j;
    float s_sum = 0.;
    vec4 v_sum = vec4(0.);
    vec2 coords, cos_gamma_sin_gamma;
    h = texture2D(adsk_results_pass1, vec2(.25)).rg;
    cos_phi_cos_theta = texture2D(adsk_results_pass1, vec2(.25)).ba;
    sin_phi_sin_theta = texture2D(adsk_results_pass1, vec2(.25, .75)).rg;
    cos_gamma_sin_gamma = texture2D(adsk_results_pass1, vec2(.25, .75)).ba;
    trans_v = texture2D(adsk_results_pass1, vec2(.75, .25)).rg;
    trans_m = mat2(texture2D(adsk_results_pass1, vec2(.75)));
    rot_m = mat2(cos_gamma_sin_gamma.s, -cos_gamma_sin_gamma.t, cos_gamma_sin_gamma.t, cos_gamma_sin_gamma.s);
    if (uv_output) {
        coords = get_coords(gl_FragCoord.xy);
        if (adsk_degrade || antialias_samples == 0) {
            gl_FragColor = vec4(coords.x, coords.y, 0., get_matte(coords));
            return;
        }
        if (antialias_samples == 1) {
            gl_FragColor = vec4(coords.x, coords.y, 0., C_1_4 * (MATTE_O(-C_1_4) + MATTE_O(vec2(C_1_4, -C_1_4)) + MATTE_O(vec2(-C_1_4, C_1_4)) + MATTE_O(C_1_4)));
            return;
        }
        if (antialias_samples == 2) {
            gl_FragColor = vec4(coords.x, coords.y, 0., C_1_16 * (MATTE_O(-C_3_8) + MATTE_O(vec2(-C_1_8, -C_3_8)) + MATTE_O(vec2(C_1_8, -C_3_8)) + MATTE_O(vec2(C_3_8, -C_3_8)) + MATTE_O(vec2(-C_3_8, -C_1_8)) + MATTE_O(-C_1_8) + MATTE_O(vec2(C_1_8, -C_1_8)) + MATTE_O(vec2(C_3_8, -C_1_8)) + MATTE_O(vec2(-C_3_8, C_1_8)) + MATTE_O(vec2(-C_1_8, C_1_8)) + MATTE_O(C_1_8) + MATTE_O(vec2(C_3_8, C_1_8)) + MATTE_O(vec2(-C_3_8, C_3_8)) + MATTE_O(vec2(-C_1_8, C_3_8)) + MATTE_O(vec2(C_1_8, C_3_8)) + MATTE_O(C_3_8)));
            return;
        }
        if (antialias_samples == 3) {
            gl_FragColor = vec4(coords.x, coords.y, 0., C_1_64 * (MATTE_O(-C_7_16) + MATTE_O(vec2(-C_5_16, -C_7_16)) + MATTE_O(vec2(-C_3_16, -C_7_16)) + MATTE_O(vec2(-C_1_16, -C_7_16)) + MATTE_O(vec2(C_1_16, -C_7_16)) + MATTE_O(vec2(C_3_16, -C_7_16)) + MATTE_O(vec2(C_5_16, -C_7_16)) + MATTE_O(vec2(C_7_16, -C_7_16)) + MATTE_O(vec2(-C_7_16, -C_5_16)) + MATTE_O(-C_5_16) + MATTE_O(vec2(-C_3_16, -C_5_16)) + MATTE_O(vec2(-C_1_16, -C_5_16)) + MATTE_O(vec2(C_1_16, -C_5_16)) + MATTE_O(vec2(C_3_16, -C_5_16)) + MATTE_O(vec2(C_5_16, -C_5_16)) + MATTE_O(vec2(C_7_16, -C_5_16)) + MATTE_O(vec2(-C_7_16, -C_3_16)) + MATTE_O(vec2(-C_5_16, -C_3_16)) + MATTE_O(-C_3_16) + MATTE_O(vec2(-C_1_16, -C_3_16)) + MATTE_O(vec2(C_1_16, -C_3_16)) + MATTE_O(vec2(C_3_16, -C_3_16)) + MATTE_O(vec2(C_5_16, -C_3_16)) + MATTE_O(vec2(C_7_16, -C_3_16)) + MATTE_O(vec2(-C_7_16, -C_1_16)) + MATTE_O(vec2(-C_5_16, -C_1_16)) + MATTE_O(vec2(-C_3_16, -C_1_16)) + MATTE_O(-C_1_16) + MATTE_O(vec2(C_1_16, -C_1_16)) + MATTE_O(vec2(C_3_16, -C_1_16)) + MATTE_O(vec2(C_5_16, -C_1_16)) + MATTE_O(vec2(C_7_16, -C_1_16)) + MATTE_O(vec2(-C_7_16, C_1_16)) + MATTE_O(vec2(-C_5_16, C_1_16)) + MATTE_O(vec2(-C_3_16, C_1_16)) + MATTE_O(vec2(-C_1_16, C_1_16)) + MATTE_O(C_1_16) + MATTE_O(vec2(C_3_16, C_1_16)) + MATTE_O(vec2(C_5_16, C_1_16)) + MATTE_O(vec2(C_7_16, C_1_16)) + MATTE_O(vec2(-C_7_16, C_3_16)) + MATTE_O(vec2(-C_5_16, C_3_16)) + MATTE_O(vec2(-C_3_16, C_3_16)) + MATTE_O(vec2(-C_1_16, C_3_16)) + MATTE_O(vec2(C_1_16, C_3_16)) + MATTE_O(C_3_16) + MATTE_O(vec2(C_5_16, C_3_16)) + MATTE_O(vec2(C_7_16, C_3_16)) + MATTE_O(vec2(-C_7_16, C_5_16)) + MATTE_O(vec2(-C_5_16, C_5_16)) + MATTE_O(vec2(-C_3_16, C_5_16)) + MATTE_O(vec2(-C_1_16, C_5_16)) + MATTE_O(vec2(C_1_16, C_5_16)) + MATTE_O(vec2(C_3_16, C_5_16)) + MATTE_O(C_5_16) + MATTE_O(vec2(C_7_16, C_5_16)) + MATTE_O(vec2(-C_7_16, C_7_16)) + MATTE_O(vec2(-C_5_16, C_7_16)) + MATTE_O(vec2(-C_3_16, C_7_16)) + MATTE_O(vec2(-C_1_16, C_7_16)) + MATTE_O(vec2(C_1_16, C_7_16)) + MATTE_O(vec2(C_3_16, C_7_16)) + MATTE_O(vec2(C_5_16, C_7_16)) + MATTE_O(C_7_16)));
            return;
        }
        if (antialias_samples == 4) {
            for (i = -15; i < 16; i += 2) {
                for (j = -15; j < 16; j += 2)
                    s_sum += MATTE_O(C_1_32 * vec2(i, j));
            }
            gl_FragColor = vec4(coords.x, coords.y, 0., C_1_256 * s_sum);
            return;
        }
        if (antialias_samples == 5) {
            for (i = -31; i < 32; i += 2) {
                for (j = -31; j < 32; j += 2)
                    s_sum += MATTE_O(C_1_64 * vec2(i, j));
            }
            gl_FragColor = vec4(coords.x, coords.y, 0., C_1_1024 * s_sum);
            return;
        }
        for (i = -63; i < 64; i += 2) {
            for (j = -63; j < 64; j += 2)
                s_sum += MATTE_O(C_1_128 * vec2(i, j));
        }
        gl_FragColor = vec4(coords.x, coords.y, 0., C_1_4096 * s_sum);
        return;
    }
    if (adsk_degrade || antialias_samples == 0) {
        gl_FragColor = TEX_N();
        return;
    }
    if (antialias_samples == 1) {
        gl_FragColor = C_1_4 * (TEX_O(-C_1_4) + TEX_O(vec2(C_1_4, -C_1_4)) + TEX_O(vec2(-C_1_4, C_1_4)) + TEX_O(C_1_4));
        return;
    }
    if (antialias_samples == 2) {
        gl_FragColor = C_1_16 * (TEX_O(-C_3_8) + TEX_O(vec2(-C_1_8, -C_3_8)) + TEX_O(vec2(C_1_8, -C_3_8)) + TEX_O(vec2(C_3_8, -C_3_8)) + TEX_O(vec2(-C_3_8, -C_1_8)) + TEX_O(-C_1_8) + TEX_O(vec2(C_1_8, -C_1_8)) + TEX_O(vec2(C_3_8, -C_1_8)) + TEX_O(vec2(-C_3_8, C_1_8)) + TEX_O(vec2(-C_1_8, C_1_8)) + TEX_O(C_1_8) + TEX_O(vec2(C_3_8, C_1_8)) + TEX_O(vec2(-C_3_8, C_3_8)) + TEX_O(vec2(-C_1_8, C_3_8)) + TEX_O(vec2(C_1_8, C_3_8)) + TEX_O(C_3_8));
        return;
    }
    if (antialias_samples == 3) {
        gl_FragColor = C_1_64 * (TEX_O(-C_7_16) + TEX_O(vec2(-C_5_16, -C_7_16)) + TEX_O(vec2(-C_3_16, -C_7_16)) + TEX_O(vec2(-C_1_16, -C_7_16)) + TEX_O(vec2(C_1_16, -C_7_16)) + TEX_O(vec2(C_3_16, -C_7_16)) + TEX_O(vec2(C_5_16, -C_7_16)) + TEX_O(vec2(C_7_16, -C_7_16)) + TEX_O(vec2(-C_7_16, -C_5_16)) + TEX_O(-C_5_16) + TEX_O(vec2(-C_3_16, -C_5_16)) + TEX_O(vec2(-C_1_16, -C_5_16)) + TEX_O(vec2(C_1_16, -C_5_16)) + TEX_O(vec2(C_3_16, -C_5_16)) + TEX_O(vec2(C_5_16, -C_5_16)) + TEX_O(vec2(C_7_16, -C_5_16)) + TEX_O(vec2(-C_7_16, -C_3_16)) + TEX_O(vec2(-C_5_16, -C_3_16)) + TEX_O(-C_3_16) + TEX_O(vec2(-C_1_16, -C_3_16)) + TEX_O(vec2(C_1_16, -C_3_16)) + TEX_O(vec2(C_3_16, -C_3_16)) + TEX_O(vec2(C_5_16, -C_3_16)) + TEX_O(vec2(C_7_16, -C_3_16)) + TEX_O(vec2(-C_7_16, -C_1_16)) + TEX_O(vec2(-C_5_16, -C_1_16)) + TEX_O(vec2(-C_3_16, -C_1_16)) + TEX_O(-C_1_16) + TEX_O(vec2(C_1_16, -C_1_16)) + TEX_O(vec2(C_3_16, -C_1_16)) + TEX_O(vec2(C_5_16, -C_1_16)) + TEX_O(vec2(C_7_16, -C_1_16)) + TEX_O(vec2(-C_7_16, C_1_16)) + TEX_O(vec2(-C_5_16, C_1_16)) + TEX_O(vec2(-C_3_16, C_1_16)) + TEX_O(vec2(-C_1_16, C_1_16)) + TEX_O(C_1_16) + TEX_O(vec2(C_3_16, C_1_16)) + TEX_O(vec2(C_5_16, C_1_16)) + TEX_O(vec2(C_7_16, C_1_16)) + TEX_O(vec2(-C_7_16, C_3_16)) + TEX_O(vec2(-C_5_16, C_3_16)) + TEX_O(vec2(-C_3_16, C_3_16)) + TEX_O(vec2(-C_1_16, C_3_16)) + TEX_O(vec2(C_1_16, C_3_16)) + TEX_O(C_3_16) + TEX_O(vec2(C_5_16, C_3_16)) + TEX_O(vec2(C_7_16, C_3_16)) + TEX_O(vec2(-C_7_16, C_5_16)) + TEX_O(vec2(-C_5_16, C_5_16)) + TEX_O(vec2(-C_3_16, C_5_16)) + TEX_O(vec2(-C_1_16, C_5_16)) + TEX_O(vec2(C_1_16, C_5_16)) + TEX_O(vec2(C_3_16, C_5_16)) + TEX_O(C_5_16) + TEX_O(vec2(C_7_16, C_5_16)) + TEX_O(vec2(-C_7_16, C_7_16)) + TEX_O(vec2(-C_5_16, C_7_16)) + TEX_O(vec2(-C_3_16, C_7_16)) + TEX_O(vec2(-C_1_16, C_7_16)) + TEX_O(vec2(C_1_16, C_7_16)) + TEX_O(vec2(C_3_16, C_7_16)) + TEX_O(vec2(C_5_16, C_7_16)) + TEX_O(C_7_16));
        return;
    }
    if (antialias_samples == 4) {
        for (i = -15; i < 16; i += 2) {
            for (j = -15; j < 16; j += 2)
                v_sum += TEX_O(C_1_32 * vec2(i, j));
        }
        gl_FragColor = C_1_256 * v_sum;
        return;
    }
    if (antialias_samples == 5) {
        for (i = -31; i < 32; i += 2) {
            for (j = -31; j < 32; j += 2)
                v_sum += TEX_O(C_1_64 * vec2(i, j));
        }
        gl_FragColor = C_1_1024 * v_sum;
        return;
    }
    for (i = -63; i < 64; i += 2) {
        for (j = -63; j < 64; j += 2)
            v_sum += TEX_O(C_1_128 * vec2(i, j));
    }
    gl_FragColor = C_1_4096 * v_sum;
}
