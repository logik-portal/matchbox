#version 430

/*
**MIT License
**
**Copyright (c) 2026
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
    uint r_mode;
    vec2 r_pos;
    float r_ana;
    uint r_n;
    uint d_mode;
    vec2 d_pos;
    float d_ana;
    vec3 r_p;
    vec3 d_p;
};

layout (binding = 3) uniform sampler2D r_st;
layout (binding = 4) uniform sampler2D d_st;
layout (binding = 5) uniform sampler2D adsk_results_pass1;

float result_frameratio;
float d_s;
vec2 h;
mat2 trans_m;
vec2 trans_v;
vec2 cos_phi_cos_theta;
vec2 sin_phi_sin_theta;
mat2 rot_m;
float front_frameratio;
float r_s;

float sqr(const vec2 x) {
    return dot(x, x);
}

vec2 get_coords(vec2 coords) {
    coords /= vec2(adsk_result_w, adsk_result_h);
    switch (d_mode) {
    case 1:
        {
            coords -= d_pos;
            coords.x *= result_frameratio;
            const float r2 = sqr(vec2(coords.x / d_ana, coords.y)) * d_s;
            const vec2 d_pos_0 = vec2((d_pos.x - .5) * result_frameratio, d_pos.y - .5);
            coords = fma(coords, vec2(fma(fma(fma(d_p.p, r2, d_p.t), r2, + d_p.s), r2, 1. - (d_p.s + d_p.t + d_p.p))), d_pos_0);
        }
        break;
    case 2:
        coords = texture(d_st, coords).rg;
    default:
        coords -= .5;
        coords.x *= result_frameratio;
    }
    coords *= h.t;
    coords = (trans_m * coords + trans_v) / fma(cos_phi_cos_theta.t, fma(sin_phi_sin_theta.s, coords.x, cos_phi_cos_theta.s), sin_phi_sin_theta.t * coords.y);
    coords = rot_m * coords;
    coords /= h.s;
    switch (r_mode) {
    case 0:
        coords.x /= front_frameratio;
        coords += .5;
        break;
    case 1:
        {
            const vec2 r_pos_0 = vec2((r_pos.x - .5) * result_frameratio, r_pos.y - .5);
            coords -= r_pos_0;
            float r = length(vec2(coords.x / r_ana, coords.y));
            if (r != 0.) {
                coords /= r;
                const float y = r * r_s;
                r = y;
                const float beta = 1. - (r_p.s + r_p.t + r_p.p), c_x7 = 7. * r_p.p, b_x5 = 5. * r_p.t, a_x3 = 3. * r_p.s;
                for (uint i = 0; i < r_n; ++i) {
                    const float r2 = r * r;
                    r += fma(fma(fma(fma(r_p.p, r2, r_p.t), r2, r_p.s), r2, beta), -r, y) / fma(fma(fma(c_x7, r2, b_x5), r2, a_x3), r2, beta);
                }
                coords *= r / r_s;
            }
            coords.x /= front_frameratio;
            coords += r_pos;
            break;
        }
    default:
        coords.x /= front_frameratio;
        coords += .5;
        coords = texture(r_st, coords).rg;
    }
    return coords;
}

void main() {
    vec4 data = texelFetch(adsk_results_pass1, ivec2(0), 0);
    result_frameratio = data.r;
    d_s = data.g;
    h = data.ba;
    data = texelFetch(adsk_results_pass1, ivec2(1, 0), 0);
    cos_phi_cos_theta = data.rg;
    sin_phi_sin_theta = data.ba;
    data = texelFetch(adsk_results_pass1, ivec2(2, 0), 0);
    rot_m = mat2(data.r, -data.g, data.g, data.r);
    front_frameratio = data.b;
    r_s = data.a;
    trans_m = mat2(cos_phi_cos_theta.s, -sin_phi_sin_theta.s * sin_phi_sin_theta.t, 0., cos_phi_cos_theta.t);
    trans_v = vec2(-sin_phi_sin_theta.s, -cos_phi_cos_theta.s * sin_phi_sin_theta.t);
    fragColor = vec4(get_coords(gl_FragCoord.xy), 0., 0.);
}
