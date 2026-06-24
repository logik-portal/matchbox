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
    bool adsk_degrade;
};

layout (binding = 2) uniform UniformBlock {
    uint aa_n;
    uint kernel;
    float sigma;
    bool st;
};

layout (binding = 3) uniform sampler2D front;
layout (binding = 4) uniform sampler2D matte;
layout (binding = 5) uniform sampler2D adsk_results_pass2;

const float gauss_0[] = {.434365497, .065634503};
const float gauss_1[] = {.274112696, .160252801, .0547304898, .0109040132};
const float gauss_2[] = {.146565464, .127547232, .0965936183, .0636591827, .0365094075, .0182210823, .00791338883, .00299062441};
const float gauss_3[] = {.0745670039, .0719984597, .067123752, .0604234805, .0525184295, .0440751888, .0357151979, .0279439848, .0211105705, .0153988369, .0108455638, .00737551852, .0048429405, .00307044833, .00187962178, .00111100262};
const float gauss_4[] = {.0374472244, .0371197794, .0364734541, .0355250056, .0342986612, .0328250908, .0311401325, .029283348, .0272964869, .0252219427, .0231012812, .0209739076, .0188759312, .0168392666, .0148909948, .01305299, .0113418016, .00976876895, .0083403328, .00705850412, .0059214452, .0049241186, .00405896255, .00331655597, .00268624343, .00215669707, .00171640067, .00135404766, .00105885129, .000820770493, .000630658485, .000480344139};

float h;
vec2 hs = 1. / vec2(adsk_result_w, adsk_result_h);

vec2 get_coords(const vec2 coords) {
    return texture(adsk_results_pass2, hs * coords).rg;
}

vec4 get_tex_box(const ivec2 off) {
    const vec2 coords = get_coords(fma(vec2(h), fma(vec2(2.), vec2(off), vec2(1.)), gl_FragCoord.xy));
    const vec4 color = vec4(texture(front, coords).rgb, texture(matte, coords).b);
    return color;
}

#define CONCAT(A, B) A ## B

#define GEN_GET_TEX_GAUSS(NAME) \
vec4 CONCAT(get_tex_gauss_, NAME)(ivec2 off) { \
    const vec2 coords = get_coords(fma(vec2(h), fma(vec2(2.), vec2(off), vec2(1.)), gl_FragCoord.xy)); \
    const vec4 color = vec4(texture(front, coords).rgb, texture(matte, coords).b); \
    off.x = off.x < 0 ? -1 - off.x : off.x; \
    off.y = off.y < 0 ? -1 - off.y : off.y; \
    return (CONCAT(gauss_, NAME)[off.x] * CONCAT(gauss_, NAME)[off.y]) * color; \
}

GEN_GET_TEX_GAUSS(0)
GEN_GET_TEX_GAUSS(1)
GEN_GET_TEX_GAUSS(2)
GEN_GET_TEX_GAUSS(3)
GEN_GET_TEX_GAUSS(4)

#define GEN_GET_TEX_4(NAME, SIMPLEX) \
vec4 CONCAT(get_tex_4_, NAME)() { \
    return (SIMPLEX(ivec2(-1)) + SIMPLEX(ivec2(0, -1))) + (SIMPLEX(ivec2(-1, 0)) + SIMPLEX(ivec2(0))); \
}

GEN_GET_TEX_4(box, get_tex_box)

#define GEN_GET_TEX_16(NAME, SIMPLEX) \
vec4 CONCAT(get_tex_16_, NAME)() { \
    return (((SIMPLEX(ivec2(-2)) + SIMPLEX(ivec2(-1, -2))) + (SIMPLEX(ivec2(-2, -1)) + SIMPLEX(ivec2(-1)))) + ((SIMPLEX(ivec2(0, -2)) + SIMPLEX(ivec2(1, -2))) + (SIMPLEX(ivec2(0, -1)) + SIMPLEX(ivec2(1, -1))))) + (((SIMPLEX(ivec2(-2, 0)) + SIMPLEX(ivec2(-1, 0))) + (SIMPLEX(ivec2(-2, 1)) + SIMPLEX(ivec2(-1, 1)))) + ((SIMPLEX(ivec2(0)) + SIMPLEX(ivec2(1, 0))) + (SIMPLEX(ivec2(0, 1)) + SIMPLEX(ivec2(1))))); \
}

GEN_GET_TEX_16(box, get_tex_box)
GEN_GET_TEX_16(gauss, get_tex_gauss_0)

#define GEN_GET_TEX_64(NAME, SIMPLEX) \
vec4 CONCAT(get_tex_64_, NAME)(const ivec2 off) { \
    return (((((SIMPLEX(off + ivec2(-4)) + SIMPLEX(off + ivec2(-3, -4))) + (SIMPLEX(off + ivec2(-4, -3)) + SIMPLEX(off + ivec2(-3)))) + ((SIMPLEX(off + ivec2(-2, -4)) + SIMPLEX(off + ivec2(-1, -4))) + (SIMPLEX(off + ivec2(-2, -3)) + SIMPLEX(off + ivec2(-1, -3))))) + (((SIMPLEX(off + ivec2(-4, -2)) + SIMPLEX(off + ivec2(-3, -2))) + (SIMPLEX(off + ivec2(-4, -1)) + SIMPLEX(off + ivec2(-3, -1)))) + ((SIMPLEX(off + ivec2(-2)) + SIMPLEX(off + ivec2(-1, -2))) + (SIMPLEX(off + ivec2(-2, -1)) + SIMPLEX(off + ivec2(-1)))))) + ((((SIMPLEX(off + ivec2(0, -4)) + SIMPLEX(off + ivec2(1, -4))) + (SIMPLEX(off + ivec2(0, -3)) + SIMPLEX(off + ivec2(1, -3)))) + ((SIMPLEX(off + ivec2(2, -4)) + SIMPLEX(off + ivec2(3, -4))) + (SIMPLEX(off + ivec2(2, -3)) + SIMPLEX(off + ivec2(3, -3))))) + (((SIMPLEX(off + ivec2(0, -2)) + SIMPLEX(off + ivec2(1, -2))) + (SIMPLEX(off + ivec2(0, -1)) + SIMPLEX(off + ivec2(1, -1)))) + ((SIMPLEX(off + ivec2(2, -2)) + SIMPLEX(off + ivec2(3, -2))) + (SIMPLEX(off + ivec2(2, -1)) + SIMPLEX(off + ivec2(3, -1))))))) + (((((SIMPLEX(off + ivec2(-4, 0)) + SIMPLEX(off + ivec2(-3, 0))) + (SIMPLEX(off + ivec2(-4, 1)) + SIMPLEX(off + ivec2(-3, 1)))) + ((SIMPLEX(off + ivec2(-2, 0)) + SIMPLEX(off + ivec2(-1, 0))) + (SIMPLEX(off + ivec2(-2, 1)) + SIMPLEX(off + ivec2(-1, 1))))) + (((SIMPLEX(off + ivec2(-4, 2)) + SIMPLEX(off + ivec2(-3, 2))) + (SIMPLEX(off + ivec2(-4, 3)) + SIMPLEX(off + ivec2(-3, 3)))) + ((SIMPLEX(off + ivec2(-2, 2)) + SIMPLEX(off + ivec2(-1, 2))) + (SIMPLEX(off + ivec2(-2, 3)) + SIMPLEX(off + ivec2(-1, 3)))))) + ((((SIMPLEX(off) + SIMPLEX(off + ivec2(1, 0))) + (SIMPLEX(off + ivec2(0, 1)) + SIMPLEX(off + ivec2(1)))) + ((SIMPLEX(off + ivec2(2, 0)) + SIMPLEX(off + ivec2(3, 0))) + (SIMPLEX(off + ivec2(2, 1)) + SIMPLEX(off + ivec2(3, 1))))) + (((SIMPLEX(off + ivec2(0, 2)) + SIMPLEX(off + ivec2(1, 2))) + (SIMPLEX(off + ivec2(0, 3)) + SIMPLEX(off + ivec2(1, 3)))) + ((SIMPLEX(off + ivec2(2)) + SIMPLEX(off + ivec2(3, 2))) + (SIMPLEX(off + ivec2(2, 3)) + SIMPLEX(off + ivec2(3))))))); \
}

GEN_GET_TEX_64(box, get_tex_box)
GEN_GET_TEX_64(gauss_1, get_tex_gauss_1)
GEN_GET_TEX_64(gauss_2, get_tex_gauss_2)
GEN_GET_TEX_64(gauss_3, get_tex_gauss_3)
GEN_GET_TEX_64(gauss_4, get_tex_gauss_4)

#define GEN_GET_TEX_256(NAME) \
vec4 CONCAT(get_tex_256_, NAME)(const ivec2 off) { \
    vec4 sum = vec4(0.); \
    for (int x = -4; x < 5; x += 8) { \
        vec4 sum_0 = vec4(0.); \
        for (int y = -4; y < 5; y += 8) \
            sum_0 += CONCAT(get_tex_64_, NAME)(off + ivec2(x, y)); \
        sum += sum_0; \
    } \
    return sum; \
}

GEN_GET_TEX_256(box)
GEN_GET_TEX_256(gauss_2)
GEN_GET_TEX_256(gauss_3)
GEN_GET_TEX_256(gauss_4)

#define GEN_GET_TEX_1024(NAME) \
vec4 CONCAT(get_tex_1024_, NAME)(const ivec2 off) { \
    vec4 sum = vec4(0.); \
    for (int x = -8; x < 9; x += 16) { \
        vec4 sum_0 = vec4(0.); \
        for (int y = -8; y < 9; y += 16) \
            sum_0 += CONCAT(get_tex_256_, NAME)(off + ivec2(x, y)); \
        sum += sum_0; \
    } \
    return sum; \
}

GEN_GET_TEX_1024(box)
GEN_GET_TEX_1024(gauss_3)
GEN_GET_TEX_1024(gauss_4)

#define GEN_GET_TEX_4096(NAME, FILTER_NAME) \
vec4 CONCAT(get_tex_4096_, NAME)() { \
    vec4 sum = vec4(0.); \
    for (int x = -16; x < 17; x += 32) { \
        vec4 sum_0 = vec4(0.); \
        for (int y = -16; y < 17; y += 32) \
            sum_0 += CONCAT(get_tex_1024_, FILTER_NAME)(ivec2(x, y)); \
        sum += sum_0; \
    } \
    return sum; \
}

GEN_GET_TEX_4096(box, box)
GEN_GET_TEX_4096(gauss, gauss_4)

void main() {
    if (st) {
        fragColor = texelFetch(adsk_results_pass2, ivec2(gl_FragCoord.xy), 0);
        return;
    }
    if (aa_n == 0 || adsk_degrade) {
        const vec2 coords = texelFetch(adsk_results_pass2, ivec2(gl_FragCoord.xy), 0).rg;
        fragColor = vec4(texture(front, coords).rgb, texture(matte, coords).b);
        return;
    }
    h = sigma * (bool(kernel) ? 6. : 3.46410162);
    switch (aa_n) {
    case 1:
        h *= .25;
        fragColor = .25 * get_tex_4_box();
        return;
    case 2:
        h *= .125;
        if (bool(kernel))
            fragColor = get_tex_16_gauss();
        else
            fragColor = .0625 * get_tex_16_box();
        return;
    case 3:
        h *= .0625;
        if (bool(kernel))
            fragColor = get_tex_64_gauss_1(ivec2(0));
        else
            fragColor = .015625 * get_tex_64_box(ivec2(0));
        return;
    case 4:
        h *= .03125;
        if (bool(kernel))
            fragColor = get_tex_256_gauss_2(ivec2(0));
        else
            fragColor = .00390625 * get_tex_256_box(ivec2(0));
        return;
    case 5:
        h *= .015625;
        if (bool(kernel))
            fragColor = get_tex_1024_gauss_3(ivec2(0));
        else
            fragColor = .0009765625 * get_tex_1024_box(ivec2(0));
        return;
    }
    h *= .0078125;
    if (bool(kernel))
        fragColor = get_tex_4096_gauss();
    else
        fragColor = .000244140625 * get_tex_4096_box();
}
