#version 430

/*
**MIT License
**
**Copyright (c) 2025
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

layout (location = 0) out vec4 fragColor;

layout (binding = 1) uniform AdskUniformBlock {
    float adsk_result_w, adsk_result_h;
};

layout (binding = 2) uniform UniformBlock {
    uint d_mode;
    vec2 d_pos;
    float d_ana;
    uint undist_iter;
    bool use_undist_map;
    bool use_redist_map;
    float d_a;
    float d_b;
    float d_c;
};

layout (binding = 3) uniform sampler2D undist_st;
layout (binding = 4) uniform sampler2D redist_st;
layout (binding = 5) uniform sampler2D adsk_results_pass1;

float result_frameratio;
float redist_scale;
vec2 h;
mat2 trans_m;
vec2 trans_v;
vec2 cos_phi_cos_theta;
vec2 sin_phi_sin_theta;
mat2 rot_m;
float front_frameratio;
float undist_scale_inv;

vec2 get_coords(vec2 coords) {
    coords /= vec2(adsk_result_w, adsk_result_h);
    vec2 d;
    float beta;
    if (bool(d_mode) && !(use_undist_map && use_redist_map)) {
        d = vec2(d_pos.x / d_ana, d_pos.y);
        beta = 1. - (d_a + d_b + d_c);
    }
    if (bool(d_mode / 2) && use_redist_map)
        coords = texture(redist_st, coords).rg;
    coords -= .5;
    coords.x *= result_frameratio;
    if (bool(d_mode / 2) && !use_redist_map) {
        coords.x /= d_ana;
        coords -= d;
        float r2 = dot(coords, coords) * redist_scale;
        coords = d + coords * (((d_c * r2 + d_b) * r2 + d_a) * r2 + beta);
        coords.x *= d_ana;
    }
    coords *= h.t;
    coords = (trans_m * coords + trans_v) / (cos_phi_cos_theta.t * (sin_phi_sin_theta.s * coords.x + cos_phi_cos_theta.s) + sin_phi_sin_theta.t * coords.y);
    coords = rot_m * coords;
    coords /= h.s;
    if (bool(d_mode % 2) && use_undist_map) {
        coords.x /= front_frameratio;
        coords += .5;
        coords = texture(undist_st, coords).rg;
    }
    else {
        if (bool(d_mode % 2)) {
            coords.x /= d_ana;
            coords -= d;
            float r = length(coords);
            if (r != 0.) {
                coords /= r;
                float y = r / undist_scale_inv;
                r = y;
                float c_x7 = 7. * d_c, b_x5 = 5. * d_b, a_x3 = 3. * d_a;
                for (uint i = 0; i < undist_iter; ++i) {
                    float r2 = r * r;
                    r += 1. * (y - r * ((((d_c * r2 + d_b) * r2 + d_a) * r2) + beta)) / (((c_x7 * r2 + b_x5) * r2 + a_x3) * r2 + beta);
                }
                coords *= r * undist_scale_inv;
            }
            coords += d;
            coords.x *= d_ana;
        }
        coords.x /= front_frameratio;
        coords += .5;
    }
    return coords;
}

void main() {
    vec4 data = texelFetch(adsk_results_pass1, ivec2(0), 0);
    result_frameratio = data.r;
    redist_scale = data.g;
    h = data.ba;
    trans_m = mat2(texelFetch(adsk_results_pass1, ivec2(1, 0), 0));
    data = texelFetch(adsk_results_pass1, ivec2(2, 0), 0);
    trans_v = data.rg;
    cos_phi_cos_theta = data.ba;
    data = texelFetch(adsk_results_pass1, ivec2(0, 1), 0);
    sin_phi_sin_theta = data.rg;
    rot_m = mat2(data.b, -data.a, data.a, data.b);
    vec2 data2 = texelFetch(adsk_results_pass1, ivec2(1), 0).rg;
    front_frameratio = data2.r;
    undist_scale_inv = data2.g;
    fragColor = vec4(get_coords(gl_FragCoord.xy), 0., 0.);
}
