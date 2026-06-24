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
    float adsk_results_pass2_w, adsk_results_pass2_h;
};

layout (binding = 2) uniform UniformBlock {
    uint sst;
    uint lc;
    bool pv;
    uint pvf;
};

layout (binding = 3) uniform sampler2D adsk_results_pass2;

int w, h;

vec2 fetch_mm(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(max(0, x), max(0, y)), 0).rb;
}

vec2 fetch_0m(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(x, max(0, y)), 0).rb;
}

vec2 fetch_pm(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(min(w - 1, x), max(0, y)), 0).rb;
}

vec2 fetch_m0(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(max(0, x), y), 0).rb;
}

vec2 fetch_00(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(x, y), 0).rb;
}

vec2 fetch_p0(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(min(w - 1, x), y), 0).rb;
}

vec2 fetch_mp(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(max(0, x), min(h - 1, y)), 0).rb;
}

vec2 fetch_0p(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(x, min(h - 1, y)), 0).rb;
}

vec2 fetch_pp(int x, int y) {
    return texelFetch(adsk_results_pass2, ivec2(min(w - 1, x), min(h - 1, y)), 0).rb;
}

void main() {
#define LEFT !bool(x % 2)
#define TOP y % 2 != h_0 % 2
    const int x = int(gl_FragCoord.x), y = int(gl_FragCoord.y);
    vec3 c;
    if (pv && sst != 2) {
        const float l = texelFetch(adsk_results_pass2, ivec2(x, y), 0).y;
        const int w_0 = int(adsk_results_pass2_w);
        const int x_2 = x / 2;
        w = (w_0 + 1) / 2;
        vec2 chroma;
        if (bool(sst)) {
            if (LEFT)
                chroma = fetch_00(x_2, y);
            else
                chroma = .5 * (fetch_00(x_2, y) + fetch_p0(x_2 + 1, y));
        }
        else {
            const int h_0 = int(adsk_results_pass2_h);
            const int y_2 = (y + h_0 % 2) / 2;
            h = (h_0 + 1) / 2;
            switch (lc) {
            case 0:
                switch (pvf) {
                case 0:
                    if (LEFT)
                        chroma = fetch_00(x_2, y_2);
                    else
                        chroma = .5 * (fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2));
                    break;
                case 1:
                    if (LEFT) {
                        if (TOP)
                            chroma = fma(vec2(.25), fetch_0p(x_2, y_2 + 1), .75 * fetch_00(x_2, y_2));
                        else
                            chroma = fma(vec2(.75), fetch_00(x_2, y_2), .25 * fetch_0m(x_2, y_2 - 1));
                    }
                    else {
                        const vec2 pos_0 = fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2);
                        vec2 pos_1;
                        if (TOP)
                            pos_1 = fetch_0p(x_2, y_2 + 1) + fetch_pp(x_2 + 1, y_2 + 1);
                        else
                            pos_1 = fetch_0m(x_2, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1);
                        chroma = fma(vec2(.125), pos_1, .375 * pos_0);
                    }
                    break;
                default:
                    if (LEFT) {
                        const vec2 pos_3 = fetch_m0(x_2 - 1, y_2) + fetch_p0(x_2 + 1, y_2);
                        const vec2 pos_5 = fetch_00(x_2, y_2);
                        vec2 pos_0, pos_1, pos_2, pos_4;
                        if (TOP) {
                            pos_0 = fetch_0m(x_2, y_2 - 1);
                            pos_1 = fetch_mm(x_2 - 1, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1);
                            pos_2 = fetch_mp(x_2 - 1, y_2 + 1) + fetch_pp(x_2 + 1, y_2 + 1);
                            pos_4 = fetch_0p(x_2, y_2 + 1);
                        }
                        else {
                            pos_0 = fetch_0p(x_2, y_2 + 1);
                            pos_1 = fetch_mp(x_2 - 1, y_2 + 1) + fetch_pm(x_2 + 1, y_2 + 1);
                            pos_2 = fetch_mm(x_2 - 1, y_2 - 1) + fetch_pp(x_2 + 1, y_2 - 1);
                            pos_4 = fetch_0m(x_2, y_2 - 1);
                        }
                        vec2 tmp = fma(vec2(.0078125), pos_1, .046875 * pos_0);
                        tmp = fma(vec2(.0390625), pos_2, tmp);
                        tmp = fma(vec2(.078125), pos_3, tmp);
                        tmp = fma(vec2(.234375), pos_4, tmp);
                        chroma = fma(vec2(.46875), pos_5, tmp);
                    }
                    else {
                        const vec2 pos_2 = fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2);
                        vec2 pos_0, pos_1;
                        if (TOP) {
                            pos_0 = fetch_0m(x_2, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1);
                            pos_1 = fetch_0p(x_2, y_2 + 1) + fetch_pp(x_2 + 1, y_2 + 1);
                        }
                        else {
                            pos_0 = fetch_0p(x_2, y_2 + 1) + fetch_pp(x_2 + 1, y_2 + 1);
                            pos_1 = fetch_0m(x_2, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1);
                        }
                        const vec2 tmp = fma(vec2(.15625), pos_1, .03125 * pos_0);
                        chroma = fma(vec2(.3125), pos_2, tmp);
                    }
                }
                break;
            case 1:
                if (bool(pvf)) {
                    vec2 tmp;
                    if (LEFT) {
                        if (TOP)
                            tmp = fma(vec2(.1875), fetch_m0(x_2 - 1, y_2) + fetch_0p(x_2, y_2 + 1), .0625 * fetch_mp(x_2 - 1, y_2 + 1));
                        else
                            tmp = fma(vec2(.1875), fetch_0m(x_2, y_2 - 1) + fetch_m0(x_2 - 1, y_2), .0625 * fetch_mm(x_2 - 1, y_2 - 1));
                    }
                    else {
                        if (TOP)
                            tmp = fma(vec2(.1875), fetch_p0(x_2 + 1, y_2) + fetch_0p(x_2, y_2 + 1), .0625 * fetch_pp(x_2 + 1, y_2 + 1));
                        else
                            tmp = fma(vec2(.1875), fetch_0m(x_2, y_2 - 1) + fetch_p0(x_2 + 1, y_2), .0625 * fetch_pm(x_2 + 1, y_2 - 1));
                    }
                    chroma = fma(vec2(.5625), fetch_00(x_2, y_2), tmp);
                }
                else
                    chroma = fetch_00(x_2, y_2);
                break;
            default:
                if (pvf == 2) {
                    if (LEFT) {
                        if (TOP) {
                            const vec2 pos_0 = (fetch_mm(x_2 - 1, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1)) + (fetch_mp(x_2 - 1, y_2 + 1) + fetch_pp(x_2 + 1, y_2 + 1));
                            const vec2 pos_1 = (fetch_0m(x_2, y_2 - 1) + fetch_m0(x_2 - 1, y_2)) + (fetch_p0(x_2 + 1, y_2) + fetch_0p(x_2, y_2 + 1));
                            const vec2 pos_2 = fetch_00(x_2, y_2);
                            const vec2 tmp = fma(vec2(.09375), pos_1, .015625 * pos_0); 
                            chroma = fma(vec2(.5625), pos_2, tmp);
                        }
                        else {
                            const vec2 pos_0 = (fetch_mm(x_2 - 1, y_2 - 1) + fetch_m0(x_2 - 1, y_2)) + (fetch_pm(x_2 + 1, y_2 - 1) + fetch_p0(x_2 + 1, y_2));
                            const vec2 pos_1 = fetch_0m(x_2, y_2 - 1) + fetch_00(x_2, y_2);
                            chroma = fma(vec2(.375), pos_1, .0625 * pos_0);
                        }
                    }
                    else {
                        if (TOP) {
                            const vec2 pos_0 = (fetch_0m(x_2, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1)) + (fetch_0p(x_2, y_2 + 1) + fetch_pp(x_2 + 1, y_2 + 1));
                            const vec2 pos_1 = fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2);
                            chroma = fma(vec2(.375), pos_1, .0625 * pos_0);
                        }
                        else
                            chroma = .25 * ((fetch_0m(x_2, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1)) + (fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2)));
                    }
                }
                else {
                    if (LEFT) {
                        if (TOP)
                            chroma = fetch_00(x_2, y_2);
                        else
                            chroma = .5 * (fetch_0m(x_2, y_2 - 1) + fetch_00(x_2, y_2));
                    }
                    else {
                        if (TOP)
                            chroma = .5 * (fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2));
                        else
                            chroma = .25 * ((fetch_0m(x_2, y_2 - 1) + fetch_pm(x_2 + 1, y_2 - 1)) + (fetch_00(x_2, y_2) + fetch_p0(x_2 + 1, y_2)));
                    }
                }
            }
        }
        c = vec3(chroma.s, l, chroma.t);
    }
    else
        c = texelFetch(adsk_results_pass2, ivec2(x, y), 0).rgb;
    fragColor = vec4(c, 0.);
}
