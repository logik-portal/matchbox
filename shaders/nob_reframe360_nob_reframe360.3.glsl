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

const float gauss_2[] = {6.5634503e-02, 4.343655e-01};
const float gauss_3[] = {1.0904013e-02, 5.473049e-02, 1.602528e-01, 2.741127e-01};
const float gauss_4[] = {2.9906244e-03, 7.9133888e-03, 1.8221082e-02, 3.6509407e-02, 6.3659183e-02, 9.6593618e-02, 1.2754723e-01, 1.4656546e-01};
const float gauss_5[] = {1.1110026e-03, 1.8796218e-03, 3.0704483e-03, 4.8429405e-03, 7.3755185e-03, 1.0845564e-02, 1.5398837e-02, 2.1110571e-02, 2.7943985e-02, 3.5715198e-02, 4.4075189e-02, 5.251843e-02, 6.0423481e-02, 6.7123752e-02, 7.199846e-02, 7.4567004e-02};
const float gauss_6[] = {4.8034414e-04, 6.3065849e-04, 8.2077049e-04, 1.0588513e-03, 1.3540477e-03, 1.7164007e-03, 2.1566971e-03, 2.6862434e-03, 3.316556e-03, 4.0589625e-03, 4.9241186e-03, 5.9214452e-03, 7.0585041e-03, 8.3403328e-03, 9.768769e-03, 1.1341802e-02, 1.305299e-02, 1.4890995e-02, 1.6839267e-02, 1.8875931e-02, 2.0973908e-02, 2.3101281e-02, 2.5221943e-02, 2.7296487e-02, 2.9283348e-02, 3.1140132e-02, 3.2825091e-02, 3.4298661e-02, 3.5525006e-02, 3.6473454e-02, 3.7119779e-02, 3.7447224e-02};

float h;
int o;
float weight;
float weights[64];

vec2 get_coords(vec2 coords) {
    vec4 coords4 = texture(adsk_results_pass2, coords / vec2(adsk_result_w, adsk_result_h));
    if (coords4.a != 0.)
        return coords4.bg;
    return coords4.rg;
}

vec4 get_tex(ivec2 off) {
    vec2 coords = get_coords(gl_FragCoord.xy + h * (2 * off + o));
    vec4 color = vec4(texture(front, coords).rgb, texture(matte, coords).b);
    if (bool(kernel))
        return (weights[off.x] * weights[off.y]) * color;
    return weight * color;
}

vec4 get_tex_4() {
    return (get_tex(ivec2(0)) + get_tex(ivec2(1, 0))) + (get_tex(ivec2(0, 1)) + get_tex(ivec2(1)));
}

vec4 get_tex_16() {
    return (((get_tex(ivec2(0)) + get_tex(ivec2(1, 0))) + (get_tex(ivec2(0, 1)) + get_tex(ivec2(1)))) + ((get_tex(ivec2(2, 0)) + get_tex(ivec2(3, 0))) + (get_tex(ivec2(2, 1)) + get_tex(ivec2(3, 1))))) + (((get_tex(ivec2(0, 2)) + get_tex(ivec2(1, 2))) + (get_tex(ivec2(0, 3)) + get_tex(ivec2(1, 3)))) + ((get_tex(ivec2(2)) + get_tex(ivec2(3, 2))) + (get_tex(ivec2(2, 3)) + get_tex(ivec2(3)))));
}

vec4 get_tex_64(ivec2 off) {
    return (((((get_tex(off) + get_tex(off + ivec2(1, 0))) + (get_tex(off + ivec2(0, 1)) + get_tex(off + 1))) + ((get_tex(off + ivec2(2, 0)) + get_tex(off + ivec2(3, 0))) + (get_tex(off + ivec2(2, 1)) + get_tex(off + ivec2(3, 1))))) + (((get_tex(off + ivec2(0, 2)) + get_tex(off + ivec2(1, 2))) + (get_tex(off + ivec2(0, 3)) + get_tex(off + ivec2(1, 3)))) + ((get_tex(off + 2) + get_tex(off + ivec2(3, 2))) + (get_tex(off + ivec2(2, 3)) + get_tex(off + 3))))) + ((((get_tex(off + ivec2(4, 0)) + get_tex(off + ivec2(5, 0))) + (get_tex(off + ivec2(4, 1)) + get_tex(off + ivec2(5, 1)))) + ((get_tex(off + ivec2(6, 0)) + get_tex(off + ivec2(7, 0))) + (get_tex(off + ivec2(6, 1)) + get_tex(off + ivec2(7, 1))))) + (((get_tex(off + ivec2(4, 2)) + get_tex(off + ivec2(5, 2))) + (get_tex(off + ivec2(4, 3)) + get_tex(off + ivec2(5, 3)))) + ((get_tex(off + ivec2(6, 2)) + get_tex(off + ivec2(7, 2))) + (get_tex(off + ivec2(6, 3)) + get_tex(off + ivec2(7, 3))))))) + (((((get_tex(off + ivec2(0, 4)) + get_tex(off + ivec2(1, 4))) + (get_tex(off + ivec2(0, 5)) + get_tex(off + ivec2(1, 5)))) + ((get_tex(off + ivec2(2, 4)) + get_tex(off + ivec2(3, 4))) + (get_tex(off + ivec2(2, 5)) + get_tex(off + ivec2(3, 5))))) + (((get_tex(off + ivec2(0, 6)) + get_tex(off + ivec2(1, 6))) + (get_tex(off + ivec2(0, 7)) + get_tex(off + ivec2(1, 7)))) + ((get_tex(off + ivec2(2, 6)) + get_tex(off + ivec2(3, 6))) + (get_tex(off + ivec2(2, 7)) + get_tex(off + ivec2(3, 7)))))) + ((((get_tex(off + 4) + get_tex(off + ivec2(5, 4))) + (get_tex(off + ivec2(4, 5)) + get_tex(off + 5))) + ((get_tex(off + ivec2(6, 4)) + get_tex(off + ivec2(7, 4))) + (get_tex(off + ivec2(6, 5)) + get_tex(off + ivec2(7, 5))))) + (((get_tex(off + ivec2(4, 6)) + get_tex(off + ivec2(5, 6))) + (get_tex(off + ivec2(4, 7)) + get_tex(off + ivec2(5, 7)))) + ((get_tex(off + 6) + get_tex(off + ivec2(7, 6))) + (get_tex(off + ivec2(6, 7)) + get_tex(off + 7))))));
}

vec4 get_tex_256(ivec2 off) {
    vec4 sum = vec4(0.);
    for (int x = 0; x < 9; x += 8) {
        vec4 sum_0 = vec4(0.);
        for (int y = 0; y < 9; y += 8)
            sum_0 += get_tex_64(off + ivec2(x, y));
        sum += sum_0;
    }
    return sum;
}

vec4 get_tex_1024(ivec2 off) {
    vec4 sum = vec4(0.);
    for (int x = 0; x < 17; x += 16) {
        vec4 sum_0 = vec4(0.);
        for (int y = 0; y < 17; y += 16)
            sum_0 += get_tex_256(off + ivec2(x, y));
        sum += sum_0;
    }
    return sum;
}

vec4 get_tex_4096() {
    vec4 sum = vec4(0.);
    for (int x = 0; x < 33; x += 32) {
        vec4 sum_0 = vec4(0.);
        for (int y = 0; y < 33; y += 32)
            sum_0 += get_tex_1024(ivec2(x, y));
        sum += sum_0;
    }
    return sum;
}

void main() {
    if (st) {
        fragColor = texelFetch(adsk_results_pass2, ivec2(gl_FragCoord.xy), 0);
        return;
    }
    if (aa_n == 0 || adsk_degrade) {
        vec2 coords = texelFetch(adsk_results_pass2, ivec2(gl_FragCoord.xy), 0).rg;
        fragColor = vec4(texture(front, coords).rgb, texture(matte, coords).b);
        return;
    }
    h = sigma * (bool(kernel) ? 6. : 3.4641016151377545870548926830117447338856105076);
    switch (aa_n) {
    case 1:
        h *= .25;
        o = -1;
        if (bool(kernel)) {
            weights[0] = .5;
            weights[1] = .5;
        }
        else
            weight = .25;
        fragColor = get_tex_4();
        return;
    case 2:
        h *= .125;
        o = -3;
        if (bool(kernel)) {
            weights[0] = gauss_2[0];
            weights[1] = gauss_2[1];
            weights[2] = gauss_2[1];
            weights[3] = gauss_2[0];
        }
        else
            weight = .0625;
        fragColor = get_tex_16();
        return;
    case 3:
        h *= .0625;
        o = -7;
        if (bool(kernel)) {
            for (uint i = 0; i < 4; ++i)
                weights[i] = gauss_3[i];
            for (uint i = 4; i < 8; ++i)
                weights[i] = gauss_3[7 - i];
        }
        else
            weight = .015625;
        fragColor = get_tex_64(ivec2(0));
        return;
    case 4:
        h *= .03125;
        o = -15;
        if (bool(kernel)) {
            for (uint i = 0; i < 8; ++i)
                weights[i] = gauss_4[i];
            for (uint i = 8; i < 16; ++i)
                weights[i] = gauss_4[15 - i];
        }
        else
            weight = .00390625;
        fragColor = get_tex_256(ivec2(0));
        return;
    case 5:
        h *= .015625;
        o = -31;
        if (bool(kernel)) {
            for (uint i = 0; i < 16; ++i)
                weights[i] = gauss_5[i];
            for (uint i = 16; i < 32; ++i)
                weights[i] = gauss_5[31 - i];
        }
        else
            weight = .0009765625;
        fragColor = get_tex_1024(ivec2(0));
        return;
    }
    h *= .0078125;
    o = -63;
    if (bool(kernel)) {
        for (uint i = 0; i < 32; ++i)
            weights[i] = gauss_6[i];
        for (uint i = 32; i < 64; ++i)
            weights[i] = gauss_6[63 - i];
    }
    else
        weight = .000244140625;
    fragColor = get_tex_4096();
}
