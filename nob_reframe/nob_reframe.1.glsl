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
    float adsk_front_w, adsk_front_h, adsk_front_frameratio, adsk_front_pixelratio, adsk_r_st_w, adsk_r_st_h, adsk_r_st_frameratio, adsk_r_st_pixelratio, adsk_result_w, adsk_result_h, adsk_result_frameratio;
};

layout (binding = 2) uniform UniformBlock {
    bool use_fov;
    float image_height;
    float f_0;
    float fov_0;
    float psi;
    bool use_abs;
    vec2 pos;
    vec2 pos_abs;
    uint mode;
    float scale;
    float f_1;
    float fov_1;
    uint r_mode;
    vec2 r_pos;
    float r_ana;
    uint d_mode;
    vec2 d_pos;
    float d_ana;
    uint force_par;
    float par;
};

layout (binding = 3) uniform sampler2D front;
layout (binding = 4) uniform sampler2D r_st;

float dist_1_2(const float x) {
    return x < .5 ? 1. - x : x;
}

void main() {
    float front_w, front_h, front_frameratio, front_pixelratio;
    if (r_mode == 2) {
        front_w = adsk_r_st_w;
        front_h = adsk_r_st_h;
        front_frameratio = adsk_r_st_frameratio;
        front_pixelratio = adsk_r_st_pixelratio;
    }
    else {
        front_w = adsk_front_w;
        front_h = adsk_front_h;
        front_frameratio = adsk_front_frameratio;
        front_pixelratio = adsk_front_pixelratio;
    }
    float result_frameratio;
    switch (force_par) {
    case 0:
        result_frameratio = adsk_result_frameratio;
        break;
    case 1:
        result_frameratio = front_pixelratio * adsk_result_w / adsk_result_h;
        break;
    default:
        result_frameratio = par * adsk_result_w / adsk_result_h;
    }
    float d_s;
    if (d_mode == 1) {
        const vec2 d = vec2(result_frameratio * dist_1_2(d_pos.x) / d_ana, dist_1_2(d_pos.y));
        d_s = 1. / dot(d, d);
    }
    float r_s;
    if (r_mode == 1) {
        const vec2 d = vec2(front_frameratio * dist_1_2(r_pos.x) / r_ana, dist_1_2(r_pos.y));
        r_s = inversesqrt(dot(d, d));
    }
    vec2 h;
    if (use_fov)
        h.s = 2. * tan(.5 * radians(fov_0));
    else
        h.s = image_height / f_0;
    switch (mode) {
    case 0:
        h.t = 100. * h.s / scale;
        break;
    case 1:
        h.t = image_height / f_1;
        break;
    default:
        h.t = 2. * tan(.5 * radians(fov_1));
    }
    vec2 cos_phi_cos_theta, sin_phi_sin_theta;
    {
        vec2 coords;
        if (use_abs)
            coords = h.t * pos_abs / vec2(adsk_result_w, adsk_result_h);
        else
            coords = h.t * (pos - .5);
        coords.x *= result_frameratio;
        cos_phi_cos_theta.s = inversesqrt(fma(coords.x, coords.x, 1.));
        coords.y *= cos_phi_cos_theta.s;
        cos_phi_cos_theta.t = inversesqrt(fma(coords.y, coords.y, 1.));
        sin_phi_sin_theta = coords * cos_phi_cos_theta;
    }
    const vec2 cos_psi_sin_psi = vec2(cos(radians(psi)), sin(radians(psi)));
    if (gl_FragCoord.x < 1.) {
        fragColor = vec4(result_frameratio, d_s, h);
        return;
    }
    if (gl_FragCoord.x < 2.) {
        fragColor = vec4(cos_phi_cos_theta, sin_phi_sin_theta);
        return;
    }
    fragColor = vec4(cos_psi_sin_psi, front_frameratio, r_s);
}
