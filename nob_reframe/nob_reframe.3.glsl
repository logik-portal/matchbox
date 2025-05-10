#version 130

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

uniform float adsk_front_w, adsk_front_h, adsk_result_w, adsk_result_h;
uniform bool adsk_degrade;
uniform sampler2D front, matte, adsk_results_pass2;
uniform int antialias_samples;
uniform float antialias_softness;
uniform bool uv_output;

vec2 get_coords(vec2 coords) {
    return texture2D(adsk_results_pass2, coords / vec2(adsk_result_w, adsk_result_h)).rg;
}

vec4 get_tex(float off) {
    ivec2 coords = ivec2(get_coords(gl_FragCoord.xy + antialias_softness * off) * vec2(adsk_front_w, adsk_front_h));
    return vec4(texelFetch(front, coords, 0).rgb, texelFetch(matte, coords, 0).b);
}

vec4 get_tex(vec2 off) {
    ivec2 coords = ivec2(get_coords(gl_FragCoord.xy + antialias_softness * off) * vec2(adsk_front_w, adsk_front_h));
    return vec4(texelFetch(front, coords, 0).rgb, texelFetch(matte, coords, 0).b);
}

void main() {
#define C_1_4096 .000244140625
#define C_1_1024 .0009765625
#define C_1_256  .00390625
#define C_1_128  .0078125
#define C_1_64   .015625
#define C_3_128  .0234375
#define C_1_32   .03125
#define C_3_64   .046875
#define C_1_16   .0625
#define C_3_32   .09375
#define C_1_8    .125
#define C_3_16   .1875
#define C_1_4    .25
#define C_3_8    .375
#define C_1_2    .5
    vec4 sum = vec4(0.);
    if (uv_output) {
        gl_FragColor = vec4(texelFetch(adsk_results_pass2, ivec2(gl_FragCoord.xy), 0).rg, 0., 0.);
        return;
    }
    if (antialias_samples == 0 || adsk_degrade) {
        gl_FragColor = get_tex(0.);
        return;
    }
    switch (antialias_samples) {
    case 1:
        gl_FragColor = C_1_4 * ((get_tex(-C_1_4) + get_tex(vec2(C_1_4, -C_1_4))) + (get_tex(vec2(-C_1_4, C_1_4)) + get_tex(C_1_4)));
        return;
    case 2:
        gl_FragColor = C_1_16 * ((((get_tex(-C_3_8) + get_tex(vec2(-C_1_8, -C_3_8))) + (get_tex(vec2(-C_3_8, -C_1_8)) + get_tex(-C_1_8))) + 
                                  ((get_tex(vec2(C_1_8, -C_3_8)) + get_tex(vec2(C_3_8, -C_3_8))) + (get_tex(vec2(C_1_8, -C_1_8)) + get_tex(vec2(C_3_8, -C_1_8))))) +
                                 (((get_tex(vec2(-C_3_8, C_1_8)) + get_tex(vec2(-C_1_8, C_1_8))) + (get_tex(vec2(-C_3_8, C_3_8)) + get_tex(vec2(-C_1_8, C_3_8)))) + 
                                  ((get_tex(C_1_8) + get_tex(vec2(C_3_8, C_1_8))) + (get_tex(vec2(C_1_8, C_3_8)) + get_tex(C_3_8)))));
        return;
    case 3:
        for (int j = -1; j < 2; j += 2) {
            vec2 off;
            vec4 sum_0 = vec4(0.);
            off.y = C_1_4 * j;
            for (int i = -1; i < 2; i += 2) {
                off.x = C_1_4 * i;
                sum_0 += (((get_tex(off - C_3_16) + get_tex(off - vec2(C_1_16, C_3_16))) + (get_tex(off - vec2(C_3_16, C_1_16)) + get_tex(off - C_1_16))) + 
                          ((get_tex(off + vec2(C_1_16, -C_3_16)) + get_tex(off + vec2(C_3_16, -C_3_16))) + (get_tex(off + vec2(C_1_16, -C_1_16)) + get_tex(off + vec2(C_3_16, -C_1_16))))) +
                         (((get_tex(off + vec2(-C_3_16, C_1_16)) + get_tex(off + vec2(-C_1_16, C_1_16))) + (get_tex(off + vec2(-C_3_16, C_3_16)) + get_tex(off + vec2(-C_1_16, C_3_16)))) + 
                          ((get_tex(off + C_1_16) + get_tex(off + vec2(C_3_16, C_1_16))) + (get_tex(off + vec2(C_1_16, C_3_16)) + get_tex(off + C_3_16))));
            }
            sum += sum_0;
        }
        gl_FragColor = C_1_64 * sum;
        return;
    case 4:
        for (int l = -1; l < 2; l += 2) {
            vec2 off_0;
            vec4 sum_2 = vec4(0.);
            off_0.y = C_1_4 * l;
            for (int k = -1; k < 2; k += 2) {
                vec4 sum_1 = vec4(0.);
                off_0.x = C_1_4 * k;
                for (int j = -1; j < 2; j += 2) {
                    vec2 off;
                    vec4 sum_0 = vec4(0.);
                    off.y = off_0.y + C_1_8 * j;
                    for (int i = -1; i < 2; i += 2) {
                        off.x = off_0.x + C_1_8 * i;
                        sum_0 += (((get_tex(off - C_3_32) + get_tex(off - vec2(C_1_32, C_3_32))) + (get_tex(off - vec2(C_3_32, C_1_32)) + get_tex(off - C_1_32))) + 
                                  ((get_tex(off + vec2(C_1_32, -C_3_32)) + get_tex(off + vec2(C_3_32, -C_3_32))) + (get_tex(off + vec2(C_1_32, -C_1_32)) + get_tex(off + vec2(C_3_32, -C_1_32))))) +
                                 (((get_tex(off + vec2(-C_3_32, C_1_32)) + get_tex(off + vec2(-C_1_32, C_1_32))) + (get_tex(off + vec2(-C_3_32, C_3_32)) + get_tex(off + vec2(-C_1_32, C_3_32)))) + 
                                  ((get_tex(off + C_1_32) + get_tex(off + vec2(C_3_32, C_1_32))) + (get_tex(off + vec2(C_1_32, C_3_32)) + get_tex(off + C_3_32))));
                    }
                    sum_1 += sum_0;
                }
                sum_2 += sum_1;
            }
            sum += sum_2;
        }
        gl_FragColor = C_1_256 * sum;
        return;
    case 5:
        for (int n = -1; n < 2; n += 2) {
            vec2 off_1;
            vec4 sum_4 = vec4(0.);
            off_1.y = C_1_4 * n;
            for (int m = -1; m < 2; m += 2) {
                vec4 sum_3 = vec4(0.);
                off_1.x = C_1_4 * m;
                for (int l = -1; l < 2; l += 2) {
                    vec2 off_0;
                    vec4 sum_2 = vec4(0.);
                    off_0.y = off_1.y + C_1_8 * l;
                    for (int k = -1; k < 2; k += 2) {
                        vec4 sum_1 = vec4(0.);
                        off_0.x = off_1.x + C_1_8 * k;
                        for (int j = -1; j < 2; j += 2) {
                            vec2 off;
                            vec4 sum_0 = vec4(0.);
                            off.y = off_0.y + C_1_16 * j;
                            for (int i = -1; i < 2; i += 2) {
                                off.x = off_0.x + C_1_16 * i;
                                sum_0 += (((get_tex(off - C_3_64) + get_tex(off - vec2(C_1_64, C_3_64))) + (get_tex(off - vec2(C_3_64, C_1_64)) + get_tex(off - C_1_64))) + 
                                          ((get_tex(off + vec2(C_1_64, -C_3_64)) + get_tex(off + vec2(C_3_64, -C_3_64))) + (get_tex(off + vec2(C_1_64, -C_1_64)) + get_tex(off + vec2(C_3_64, -C_1_64))))) +
                                         (((get_tex(off + vec2(-C_3_64, C_1_64)) + get_tex(off + vec2(-C_1_64, C_1_64))) + (get_tex(off + vec2(-C_3_64, C_3_64)) + get_tex(off + vec2(-C_1_64, C_3_64)))) + 
                                          ((get_tex(off + C_1_64) + get_tex(off + vec2(C_3_64, C_1_64))) + (get_tex(off + vec2(C_1_64, C_3_64)) + get_tex(off + C_3_64))));
                            }
                            sum_1 += sum_0;
                        }
                        sum_2 += sum_1;
                    }
                    sum_3 += sum_2;
                }
                sum_4 += sum_3;
            }
            sum += sum_4;
        }
        gl_FragColor = C_1_1024 * sum;
        return;
    }
    for (int p = -1; p < 2; p += 2) {
        vec2 off_2;
        vec4 sum_6 = vec4(0.);
        off_2.y = C_1_4 * p;
        for (int o = -1; o < 2; o += 2) {
            vec4 sum_5 = vec4(0.);
            off_2.x = C_1_4 * o;
            for (int n = -1; n < 2; n += 2) {
                vec2 off_1;
                vec4 sum_4 = vec4(0.);
                off_1.y = off_2.y + C_1_8 * n;
                for (int m = -1; m < 2; m += 2) {
                    vec4 sum_3 = vec4(0.);
                    off_1.x = off_2.x + C_1_8 * m;
                    for (int l = -1; l < 2; l += 2) {
                        vec2 off_0;
                        vec4 sum_2 = vec4(0.);
                        off_0.y = off_1.y + C_1_16 * l;
                        for (int k = -1; k < 2; k += 2) {
                            vec4 sum_1 = vec4(0.);
                            off_0.x = off_1.x + C_1_16 * k;
                            for (int j = -1; j < 2; j += 2) {
                                vec2 off;
                                vec4 sum_0 = vec4(0.);
                                off.y = off_0.y + C_1_32 * j;
                                for (int i = -1; i < 2; i += 2) {
                                    off.x = off_0.x + C_1_32 * i;
                                    sum_0 += (((get_tex(off - C_3_128) + get_tex(off - vec2(C_1_128, C_3_128))) + (get_tex(off - vec2(C_3_128, C_1_128)) + get_tex(off - C_1_128))) + 
                                              ((get_tex(off + vec2(C_1_128, -C_3_128)) + get_tex(off + vec2(C_3_128, -C_3_128))) + (get_tex(off + vec2(C_1_128, -C_1_128)) + get_tex(off + vec2(C_3_128, -C_1_128))))) +
                                             (((get_tex(off + vec2(-C_3_128, C_1_128)) + get_tex(off + vec2(-C_1_128, C_1_128))) + (get_tex(off + vec2(-C_3_128, C_3_128)) + get_tex(off + vec2(-C_1_128, C_3_128)))) + 
                                              ((get_tex(off + C_1_128) + get_tex(off + vec2(C_3_128, C_1_128))) + (get_tex(off + vec2(C_1_128, C_3_128)) + get_tex(off + C_3_128))));
                                }
                                sum_1 += sum_0;
                            }
                            sum_2 += sum_1;
                        }
                        sum_3 += sum_2;
                    }
                    sum_4 += sum_3;
                }
                sum_5 += sum_4;
            }
            sum_6 += sum_5;
        }
        sum += sum_6;
    }
    gl_FragColor = C_1_4096 * sum;
}
