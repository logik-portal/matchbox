#version 430

/*
**MIT License
**
**Copyright (c) 2024
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

layout (binding = 1) uniform UniformBlock {
    uint channel;
    uint rgb_op;
    uint type;
    float threshold_s;
    vec3 threshold_v;
    float w_r;
    float w_b;
    bool luminance_preview;
};

layout (binding = 2) uniform sampler2D front;

bool compare(float s) {
    switch (type) {
    case 0:
        return threshold_s < s;
    case 1:
        return threshold_s <= s;
    case 2:
        return s <= threshold_s;
    }
    return s < threshold_s;
}

bvec3 compare(vec3 v) {
    switch (type) {
    case 0:
        return lessThan(threshold_v, v);
    case 1:
        return lessThanEqual(threshold_v, v);
    case 2:
        return lessThanEqual(v, threshold_v);
    }
    return lessThan(v, threshold_v);
}

void main() {
    switch (channel) {
    case 0:
        fragColor = vec4(vec3(compare(texelFetch(front, ivec2(gl_FragCoord.xy), 0).r)), 0.);
        return;
    case 1:
        fragColor = vec4(vec3(compare(texelFetch(front, ivec2(gl_FragCoord.xy), 0).g)), 0.);
        return;
    case 2:
        fragColor = vec4(vec3(compare(texelFetch(front, ivec2(gl_FragCoord.xy), 0).b)), 0.);
        return;
    case 3:
        {
            float lum = dot(vec3(w_r, 1. - (w_r + w_b), w_b), texelFetch(front, ivec2(gl_FragCoord.xy), 0).rgb);
            if (luminance_preview) {
                fragColor = vec4(vec3(lum), 0.);
                return;
            }
            fragColor = vec4(vec3(compare(lum)), 0.);
            return;
        }
    }
    switch (rgb_op) {
    case 0:
        fragColor = vec4(vec3(all(compare(texelFetch(front, ivec2(gl_FragCoord.xy), 0).rgb))), 0.);
        return;
    case 1:
        fragColor = vec4(vec3(any(compare(texelFetch(front, ivec2(gl_FragCoord.xy), 0).rgb))), 0.);
        return;
    }
    fragColor = vec4(compare(texelFetch(front, ivec2(gl_FragCoord.xy), 0).rgb), 0.);
}
