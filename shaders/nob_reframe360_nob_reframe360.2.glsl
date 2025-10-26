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
    vec3 rot;
    bool distort;
    bool use_redist_map;
    vec2 d_pos;
    float d_ana;
    float d_a;
    float d_b;
    float d_c;
};

layout (binding = 3) uniform sampler2D redist_st;
layout (binding = 4) uniform sampler2D adsk_results_pass1;

float result_frameratio;
float redist_scale;
mat2 rot_m;
float h;
vec2 cos_theta_sin_theta;

vec4 get_coords(vec2 coords) {
    coords /= vec2(adsk_result_w, adsk_result_h);
    if (distort && use_redist_map)
        coords = texture(redist_st, coords).rg;
    coords -= .5;
    coords.x *= result_frameratio;
    if (distort && !use_redist_map) {
        vec2 d = vec2(d_pos.x / d_ana, d_pos.y);
        float beta = 1. - (d_a + d_b + d_c);
        coords.x /= d_ana;
        coords -= d;
        float r2 = dot(coords, coords) * redist_scale;
        coords = d + coords * (((d_c * r2 + d_b) * r2 + d_a) * r2 + beta);
        coords.x *= d_ana;
    }
    coords *= h;
    coords = rot_m * coords;
    coords.y = (cos_theta_sin_theta.s * coords.y - cos_theta_sin_theta.t) / (cos_theta_sin_theta.s + cos_theta_sin_theta.t * coords.y);
    float r = cos_theta_sin_theta.s - cos_theta_sin_theta.t * coords.y;
    coords.x *= r;
    coords *= inversesqrt(coords.x * coords.x + coords.y * coords.y + 1.);
    coords = vec2(.15915494 * asin(clamp(coords.x * inversesqrt(1. - coords.y * coords.y), -1., 1.)), sign(r) * .31830989 * asin(coords.y));
    vec2 ext;
    if (0. < r) {
        coords.x += .5;
        ext.y = 0.;
    }
    else
        ext.y = 1.;
    coords.x = mod(coords.x, 1.);
    ext.x = .5 + mod(coords.x - .5, 1.);
    coords.x += .0027777778 * rot.y;
    ext.x += .0027777778 * rot.y;
    coords.y += .5;
    return vec4(coords, ext);
}

void main() {
    vec4 data = texelFetch(adsk_results_pass1, ivec2(0), 0);
    result_frameratio = data.r;
    redist_scale = data.g;
    rot_m = mat2(data.b, -data.a, data.a, data.b);
    data = texelFetch(adsk_results_pass1, ivec2(1, 0), 0);
    h = data.r;
    cos_theta_sin_theta = data.gb;
    fragColor = get_coords(gl_FragCoord.xy);
}
