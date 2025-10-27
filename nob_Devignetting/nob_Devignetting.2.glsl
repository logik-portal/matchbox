#version 130

/*
**MIT License
**
**Copyright (c) 2023
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

#define C_64_Pi 20.371832

uniform float adsk_front_h, adsk_front_frameratio, adsk_result_w, adsk_result_h;
uniform sampler2D front, adsk_results_pass1;
uniform bool ring_1;
uniform float r_1;
uniform float r_1_px;
uniform bool ring_2;
uniform float r_2;
uniform float r_2_px;
uniform bool ring_3;
uniform float r_3;
uniform float r_3_px;
uniform bool ring_4;
uniform float r_4;
uniform float r_4_px;
uniform float anamorphic;
uniform bool highlight_rings;
uniform bool use_px;
uniform bool compensation;
uniform bool invert;

vec2 centre;
float r2_arr[4];
mat4x3 coeff;

void initializalize() {
    vec4 r2_vec;
    mat3x4 coeff_t;
    centre = texture2D(adsk_results_pass1, vec2(.166666666, .25)).rg;
    r2_vec = texture2D(adsk_results_pass1, vec2(.5, .25));
    r2_arr = float[4](r2_vec.r, r2_vec.g, r2_vec.b, r2_vec.a);
    coeff_t[0] = texture2D(adsk_results_pass1, vec2(.8333333, .25));
    coeff_t[1] = texture2D(adsk_results_pass1, vec2(.166666666, .75));
    coeff_t[2] = texture2D(adsk_results_pass1, vec2(.5, .75));
    coeff = transpose(coeff_t);
}

vec3 highlight_ring(float r, float r_0, vec3 colour, vec3 result) {
    float a = clamp(1.5 - 500. * abs(r - r_0), 0., 1.);
    return mix(result, colour, a);
}

void main() {
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec3 result, gain;
    float r2;
    initializalize();
    result = texture2D(front, coords).rgb;
    coords -= centre;
    coords.x *= adsk_front_frameratio * anamorphic;
    r2 = dot(coords, coords);
    gain = r2 * (coeff[0] + (r2 - r2_arr[0]) * (coeff[1] + (r2 - r2_arr[1]) * (coeff[2] + (r2 - r2_arr[2]) * coeff[3]))) + 1.;
    gain = invert ? 1. / gain : gain;
    result = gain * (compensation ? vec3(1.) : result);
    if (highlight_rings) {
        bool a = bool(int(C_64_Pi * atan(coords.y, coords.x) + 64.) % 2);
        float r = sqrt(r2);
        if (ring_1 || a)
            result = highlight_ring(r, use_px ? r_1_px / adsk_front_h : r_1, vec3(1., 0., 0.), result);
        if (ring_2 || !a)
            result = highlight_ring(r, use_px ? r_2_px / adsk_front_h : r_2, vec3(0., 1., 0.), result);
        if (ring_3 || a)
            result = highlight_ring(r, use_px ? r_3_px / adsk_front_h : r_3, vec3(0., 0., 1.), result);
        if (ring_4 || !a)
            result = highlight_ring(r, use_px ? r_4_px / adsk_front_h : r_4, vec3(1., 0., 1.), result);
    }
    gl_FragColor = vec4(result, 0.);
}
