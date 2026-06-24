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
    float adsk_front_w, adsk_front_h;
};

layout (binding = 2) uniform UniformBlock {
    bool ring_1;
    float r_1;
    float r_1_px;
    float y_1;
    vec3 rgb_1;
    bool ring_2;
    float r_2;
    float r_2_px;
    float y_2;
    vec3 rgb_2;
    bool ring_3;
    float r_3;
    float r_3_px;
    float y_3;
    vec3 rgb_3;
    bool ring_4;
    float r_4;
    float r_4_px;
    float y_4;
    vec3 rgb_4;
    vec2 centre;
    vec2 centre_px;
    bool use_px;
    bool enable_rgb;
};

layout (binding = 3) uniform sampler2D front;

float r2_arr[4] = float[4](0., 0., 0., 0.);
vec3 rgb_arr[4] = vec3[4](vec3(0.), vec3(0.), vec3(0.), vec3(0.));

void initialize_0(float r, const float r_px, const float y, const vec3 rgb, const uint n) {
    if (use_px)
        r = r_px / adsk_front_h;
    r *= r;
    r2_arr[n] = r;
    rgb_arr[n] = enable_rgb ? rgb : vec3(y);
}

uint initialize() {
    uint n = 0;
    if (ring_1)
        initialize_0(r_1, r_1_px, y_1, rgb_1, n++);
    if (ring_2)
        initialize_0(r_2, r_2_px, y_2, rgb_2, n++);
    if (ring_3)
        initialize_0(r_3, r_3_px, y_3, rgb_3, n++);
    if (ring_4)
        initialize_0(r_4, r_4_px, y_4, rgb_4, n++);
    return n;
}

void main() {
    const uint n = initialize();
    const float diff_1_0 = r2_arr[1] - r2_arr[0];
    const float diff_2_0 = r2_arr[2] - r2_arr[0];
    const float diff_2_1 = r2_arr[2] - r2_arr[1];
    const float diff_3_0 = r2_arr[3] - r2_arr[0];
    const float diff_3_1 = r2_arr[3] - r2_arr[1];
    const float diff_3_2 = r2_arr[3] - r2_arr[2];
    mat4x3 coeff;
    coeff[0] = n < 1 ? vec3(0.) : rgb_arr[0] / r2_arr[0];
    coeff[1] = n < 2 ? vec3(0.) : fma(-coeff[0], vec3(r2_arr[1]), rgb_arr[1]) / (r2_arr[1] * diff_1_0);
    coeff[2] = n < 3 ? vec3(0.) : fma(-fma(coeff[1], vec3(diff_2_0), coeff[0]), vec3(r2_arr[2]), rgb_arr[2]) / (r2_arr[2] * (diff_2_0 * diff_2_1));
    coeff[3] = n < 4 ? vec3(0.) : fma(-fma(fma(coeff[2], vec3(diff_3_1), coeff[1]), vec3(diff_3_0), coeff[0]), vec3(r2_arr[3]), rgb_arr[3]) / ((r2_arr[3] * diff_3_0) * (diff_3_1 * diff_3_2));
    const mat3x4 coeff_t = transpose(coeff);
    if (gl_FragCoord.x < 1.) {
        fragColor = vec4(use_px ? centre_px / vec2(adsk_front_w, adsk_front_h) + vec2(.5) : centre, 0., 0.);
        return;
    }
    if (gl_FragCoord.x < 2.) {
        fragColor = vec4(r2_arr[0], r2_arr[1], r2_arr[2], r2_arr[3]);
        return;
    }
    if (gl_FragCoord.x < 3.) {
        fragColor = coeff_t[0];
        return;
    }
    if (gl_FragCoord.x < 4.) {
        fragColor = coeff_t[1];
        return;
    }
    fragColor = coeff_t[2];
}
