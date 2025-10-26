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

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front;
uniform int type;
uniform int data_source;
uniform int rgb_mode;
uniform float red_luminance;
uniform float green_luminance;
uniform float blue_luminance;
uniform bool luminance_preview;
uniform float red_threshold;
uniform float green_threshold;
uniform float blue_threshold;
uniform vec3 rgb_threshold;
uniform float lum_threshold;

bool compare_f(float threshold, float data) {
    if (type == 0)
        return threshold < data;
    if (type == 1)
        return threshold <= data;
    if (type == 2)
        return data <= threshold;
    return data < threshold;
}

bvec3 compare_v(vec3 threshold, vec3 data) {
    if (type == 0)
        return lessThan(threshold, data);
    if (type == 1)
        return lessThanEqual(threshold,data);
    if (type == 2)
        return lessThanEqual(data, threshold);
    return lessThan(data, threshold);
}

void main(void) {
    if (data_source == 0) {
        gl_FragColor = vec4(vec3(compare_f(red_threshold, texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).r)), 0.);
        return;
    }
    if (data_source == 1) {
        gl_FragColor = vec4(vec3(compare_f(green_threshold, texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).g)), 0.);
        return;
    }
    if (data_source == 2) {
        gl_FragColor = vec4(vec3(compare_f(blue_threshold, texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).b)), 0.);
        return;
    }
    if (data_source == 3) {
        if (rgb_mode == 0) {
            gl_FragColor = vec4(vec3(all(compare_v(rgb_threshold, texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).rgb))), 0.);
            return;
        }
        if (rgb_mode == 1) {
            gl_FragColor = vec4(vec3(any(compare_v(rgb_threshold, texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).rgb))), 0.);
            return;
        }
        gl_FragColor = vec4(compare_v(rgb_threshold, texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).rgb), 0.);
        return;
    }
    if (luminance_preview) {
        gl_FragColor = vec4(vec3(dot(vec3(red_luminance, green_luminance, blue_luminance), texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).rgb)), 0.);
        return;
    }
    gl_FragColor = vec4(vec3(compare_f(lum_threshold, dot(vec3(red_luminance, green_luminance, blue_luminance), texture2D(front, gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)).rgb))), 0.);
}
