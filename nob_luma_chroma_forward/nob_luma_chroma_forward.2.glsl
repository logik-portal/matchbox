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
    float adsk_results_pass1_w, adsk_results_pass1_h;
};

layout (binding = 2) uniform UniformBlock {
    uint model;
    uint cmat0;
    uint cmat1;
    uint frng;
    uint depth;
    uint sst;
    uint lc;
    bool pv;
    bool pvc;
    bool pvq;
};

layout (binding = 3) uniform sampler2D adsk_results_pass1;

int w = int(adsk_results_pass1_w), h = int(adsk_results_pass1_h);

vec2 fetch_mm(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(max(0, x), max(0, y)), 0).rb;
}

vec2 fetch_0m(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(x, max(0, y)), 0).rb;
}

vec2 fetch_pm(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(min(w - 1, x), max(0, y)), 0).rb;
}

vec2 fetch_m0(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(max(0, x), y), 0).rb;
}

vec2 fetch_00(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(x, y), 0).rb;
}

vec2 fetch_p0(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(min(w - 1, x), y), 0).rb;
}

vec2 fetch_mp(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(max(0, x), min(h - 1, y)), 0).rb;
}

vec2 fetch_0p(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(x, min(h - 1, y)), 0).rb;
}

vec2 fetch_pp(int x, int y) {
    return texelFetch(adsk_results_pass1, ivec2(min(w - 1, x), min(h - 1, y)), 0).rb;
}

void main() {
    const float offset_c[] = {
        .501960784,
        .500488759,
        .5001221,
        .50000763
    };
    int x = int(gl_FragCoord.x), y = int(gl_FragCoord.y);
    const uint x_0 = x, y_0 = y;
    vec3 c;
    if (sst == 2)
        c = texelFetch(adsk_results_pass1, ivec2(x, y), 0).rgb;
    else {
        const float l = texelFetch(adsk_results_pass1, ivec2(x, y), 0).y;
        x *= 2;
        if (w <= x || sst == 0 && h <= 2 * y) {
            if (model == 2)
                c = vec3(offset_c[depth], l, offset_c[depth]);
            else
                c = vec3(0., l, 0.);
        }
        else {
            vec2 c_0;
            if (bool(sst))
                c_0 = fma(vec2(.25), fetch_m0(x - 1, y) + fetch_p0(x + 1, y), .5 * fetch_00(x, y));
            else {
                y = 2 * y + (1 - h % 2);
                switch (lc) {
                case 0:
                    {
                        const vec2 pos_0 = (fetch_mm(x - 1, y - 1) + fetch_pm(x + 1, y - 1)) + (fetch_m0(x - 1, y) + fetch_p0(x + 1, y));
                        const vec2 pos_1 = fetch_0m(x, y - 1) + fetch_00(x, y);
                        c_0 = fma(vec2(.25), pos_1, .125 * pos_0);
                        break;
                    }
                case 1:
                    c_0 = .25 * ((fetch_0m(x, y - 1) + fetch_pm(x + 1, y - 1)) + (fetch_00(x, y) + fetch_p0(x + 1, y)));
                    break;
                default:
                    {
                        const vec2 pos_0 = (fetch_mm(x - 1, y - 1) + fetch_pm(x + 1, y - 1)) + (fetch_mp(x - 1, y + 1) + fetch_pp(x + 1, y + 1));
                        const vec2 pos_1 = (fetch_0m(x, y - 1) + fetch_m0(x - 1, y)) + (fetch_p0(x + 1, y) + fetch_0p(x, y + 1));
                        c_0 = fma(vec2(.125), pos_1, fma(vec2(.0625), pos_0, .25 * fetch_00(x, y)));
                    }
                }
            }
            c = vec3(c_0.s, l, c_0.t);
        }
    }
    if (model != 2) {
        const float scale_y[] = {
            .858823529,
            .856304985,
            .855677656,
            .855481804
        };
        const float offset_y[] = {
            .062745098,
            .0625610948,
            .0625152625,
            .0625009537
        };
        if (bool(bool(model) ? cmat1 : cmat0)) {
            if (bool(frng))
                c.rb += offset_c[depth];
            else {
                const float scale_c[] = {
                    .878431373,
                    .875855327,
                    .875213675,
                    .875013352
                };
                c.rb = fma(vec2(scale_c[depth]), c.rb, vec2(offset_c[depth]));
                c.y = fma(scale_y[depth], c.y, offset_y[depth]);
            }
        }
        else if (frng == 0)
            c = fma(vec3(scale_y[depth]), c, vec3(offset_y[depth]));
    }
    if (pv) {
        if (pvc)
            c = clamp(c, 0., 1.);
        if (pvq) {
            const float a[] = {
                255.,
                1023.,
                4095.,
                65535.
            };
            const float b[] = {
                .0039215686274509804,
                .00097751710654936461,
                .0002442002442002442,
                1.5259021896696422e-5
            };
            c = b[depth] * round(a[depth] * c);
        }
        if (model != 2) {
            const float scale_y[] = {
                1.16438356,
                1.16780822,
                1.16866438,
                1.16893193
            };
            if (bool(bool(model) ? cmat1 : cmat0)) {
                if (bool(frng))
                    c.rb -= offset_c[depth];
                else {
                    const float scale_c[] = {
                        1.13839286,
                        1.14174107,
                        1.14257812,
                        1.1428397
                    };
                    c.rb = fma(vec2(scale_c[depth]), c.rb, vec2(-.571428571));
                    c.y = fma(scale_y[depth], c.y, -.0730593607);
                }
            }
            else if (frng == 0)
                c = fma(vec3(scale_y[depth]), c, vec3(-.0730593607));
        }
    }
    fragColor = vec4(c, 0.);
}
