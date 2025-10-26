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

uniform float adsk_front_w, adsk_front_h;
uniform sampler2D front;
uniform bool ring_1;
uniform float r_1;
uniform float r_1_px;
uniform float y_1;
uniform vec3 rgb_1;
uniform bool ring_2;
uniform float r_2;
uniform float r_2_px;
uniform float y_2;
uniform vec3 rgb_2;
uniform bool ring_3;
uniform float r_3;
uniform float r_3_px;
uniform float y_3;
uniform vec3 rgb_3;
uniform bool ring_4;
uniform float r_4;
uniform float r_4_px;
uniform float y_4;
uniform vec3 rgb_4;
uniform vec2 centre;
uniform vec2 centre_px;
uniform bool use_px;
uniform bool enable_rgb;

float r2_arr[4] = float[4](0., 0., 0., 0.);
vec3 rgb_arr[4];

uint initializalize_3(float r2, uint idx) {
    return idx + uint(r2_arr[idx] < r2);
}

uint initializalize_2(float r2, uint idx_0, uint n) {
    uint idx;
    if (idx_0 == n)
        return idx_0;
    idx = (idx_0 + n) / uint(2);
    if (r2_arr[idx] < r2)
        return initializalize_3(r2, idx);
    return initializalize_3(r2, idx_0);
}

uint initializalize_1(float r2, uint idx_0, uint n) {
    uint idx;
    if (idx_0 == n)
        return idx_0;
    idx = (idx_0 + n) / uint(2);
    if (r2_arr[idx] < r2)
        return initializalize_2(r2, idx + uint(1), n);
    return initializalize_2(r2, uint(0), idx);
}

void initializalize_0(float r, float r_px, float y, vec3 rgb, uint n) {
    uint idx;
    if (use_px)
        r = r_px / adsk_front_h;
    r *= r;
    idx = initializalize_1(r, uint(0), n);
    while (idx < n) {
        r2_arr[n] = r2_arr[n - uint(1)];
        rgb_arr[n] = rgb_arr[n - uint(1)];
        --n;
    }
    r2_arr[idx] = r;
    rgb_arr[idx] = enable_rgb ? rgb : vec3(y);
}

uint initializalize() {
    uint n = uint(0);
    if (ring_1)
        initializalize_0(r_1, r_1_px, y_1, rgb_1, n++);
    if (ring_2)
        initializalize_0(r_2, r_2_px, y_2, rgb_2, n++);
    if (ring_3)
        initializalize_0(r_3, r_3_px, y_3, rgb_3, n++);
    if (ring_4)
        initializalize_0(r_4, r_4_px, y_4, rgb_4, n++);
    return n;
}

void main() {
    uint n = initializalize();
    float diff_1_0 = r2_arr[1] - r2_arr[0];
    float diff_2_0 = r2_arr[2] - r2_arr[0];
    float diff_2_1 = r2_arr[2] - r2_arr[1];
    float diff_3_0 = r2_arr[3] - r2_arr[0];
    float diff_3_1 = r2_arr[3] - r2_arr[1];
    float diff_3_2 = r2_arr[3] - r2_arr[2];
    mat4x3 coeff;
    mat3x4 coeff_t;
    coeff[0] = n < uint(1) ? vec3(0.) : rgb_arr[0] / r2_arr[0];
    coeff[1] = n < uint(2) ? vec3(0.) : (rgb_arr[1] - r2_arr[1] * coeff[0]) / (r2_arr[1] * diff_1_0);
    coeff[2] = n < uint(3) ? vec3(0.) : (rgb_arr[2] - r2_arr[2] * (coeff[0] + diff_2_0 * coeff[1])) / (r2_arr[2] * diff_2_0 * diff_2_1);
    coeff[3] = n < uint(4) ? vec3(0.) : (rgb_arr[3] - r2_arr[3] * (coeff[0] + diff_3_0 * (coeff[1] + diff_3_1 * coeff[2]))) / (r2_arr[3] * diff_3_0 * diff_3_1 * diff_3_2);
    coeff_t = transpose(coeff);
    if (gl_FragCoord.y < 1.) {
        if (gl_FragCoord.x < 1.) {
            gl_FragColor = vec4(use_px ? centre_px / vec2(adsk_front_w, adsk_front_h) + vec2(.5) : centre, 0, 0.);
            return;
        }
        else if (gl_FragCoord.x < 2.) {
            gl_FragColor = vec4(r2_arr[0], r2_arr[1], r2_arr[2], r2_arr[3]);
            return;
        }
        gl_FragColor = coeff_t[0];
        return;
    }
    if (gl_FragCoord.x < 1.) {
        gl_FragColor = coeff_t[1];
        return;
    }
    gl_FragColor = coeff_t[2];
}
