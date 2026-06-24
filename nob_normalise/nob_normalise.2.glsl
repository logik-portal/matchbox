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
    float adsk_results_pass1_h;
};

layout (binding = 2) uniform UniformBlock {
    float w_r;
    float w_b;
    float luma;
};

layout (binding = 3) uniform sampler2D adsk_results_pass1;

vec4 get(int off) {
    return texelFetch(adsk_results_pass1, ivec2(0, off), 0);
}

vec4 acc_0() {
    return get(0);
}

vec4 acc_1(int off) {
    return get(off) + get(off + 1);
}

vec4 acc_2(int off) {
    return (get(off) + get(off + 1)) + (get(off + 2) + get(off + 3));
}

vec4 acc_3(int off) {
    return ((get(off) + get(off + 1)) + (get(off + 2) + get(off + 3))) + ((get(off + 4) + get(off + 5)) + (get(off + 6) + get(off + 7)));
}

vec4 acc_4(int off) {
    return (((get(off) + get(off + 1)) + (get(off + 2) + get(off + 3))) + ((get(off + 4) + get(off + 5)) + (get(off + 6) + get(off + 7)))) + (((get(off + 8) + get(off + 9)) + (get(off + 10) + get(off + 11))) + ((get(off + 12) + get(off + 13)) + (get(off + 14) + get(off + 15))));
}

vec4 acc_5(int off) {
    return ((((get(off) + get(off + 1)) + (get(off + 2) + get(off + 3))) + ((get(off + 4) + get(off + 5)) + (get(off + 6) + get(off + 7)))) + (((get(off + 8) + get(off + 9)) + (get(off + 10) + get(off + 11))) + ((get(off + 12) + get(off + 13)) + (get(off + 14) + get(off + 15))))) + ((((get(off + 16) + get(off + 17)) + (get(off + 18) + get(off + 19))) + ((get(off + 20) + get(off + 21)) + (get(off + 22) + get(off + 23)))) + (((get(off + 24) + get(off + 25)) + (get(off + 26) + get(off + 27))) + ((get(off + 28) + get(off + 29)) + (get(off + 30) + get(off + 31)))));
}

vec4 acc_6(int off) {
    return (((((get(off) + get(off + 1)) + (get(off + 2) + get(off + 3))) + ((get(off + 4) + get(off + 5)) + (get(off + 6) + get(off + 7)))) + (((get(off + 8) + get(off + 9)) + (get(off + 10) + get(off + 11))) + ((get(off + 12) + get(off + 13)) + (get(off + 14) + get(off + 15))))) + ((((get(off + 16) + get(off + 17)) + (get(off + 18) + get(off + 19))) + ((get(off + 20) + get(off + 21)) + (get(off + 22) + get(off + 23)))) + (((get(off + 24) + get(off + 25)) + (get(off + 26) + get(off + 27))) + ((get(off + 28) + get(off + 29)) + (get(off + 30) + get(off + 31)))))) + (((((get(off + 32) + get(off + 33)) + (get(off + 34) + get(off + 35))) + ((get(off + 36) + get(off + 37)) + (get(off + 38) + get(off + 39)))) + (((get(off + 40) + get(off + 41)) + (get(off + 42) + get(off + 43))) + ((get(off + 44) + get(off + 45)) + (get(off + 46) + get(off + 47))))) + ((((get(off + 48) + get(off + 49)) + (get(off + 50) + get(off + 51))) + ((get(off + 52) + get(off + 53)) + (get(off + 54) + get(off + 55)))) + (((get(off + 56) + get(off + 57)) + (get(off + 58) + get(off + 59))) + ((get(off + 60) + get(off + 61)) + (get(off + 62) + get(off + 63))))));
}

vec4 acc_7(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 6) + 1; off_0 += (1 << 6))
        sum += acc_6(off + off_0);
    return sum;
}

vec4 acc_8(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 7) + 1; off_0 += (1 << 7))
        sum += acc_7(off + off_0);
    return sum;
}

vec4 acc_9(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 8) + 1; off_0 += (1 << 8))
        sum += acc_8(off + off_0);
    return sum;
}

vec4 acc_10(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 9) + 1; off_0 += (1 << 9))
        sum += acc_9(off + off_0);
    return sum;
}

vec4 acc_11(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 10) + 1; off_0 += (1 << 10))
        sum += acc_10(off + off_0);
    return sum;
}

vec4 acc_12(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 11) + 1; off_0 += (1 << 11))
        sum += acc_11(off + off_0);
    return sum;
}

vec4 acc_13(int off) {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 12) + 1; off_0 += (1 << 12))
        sum += acc_12(off + off_0);
    return sum;
}

vec4 acc_14() {
    vec4 sum = vec4(0.);
    for (int off_0 = 0; off_0 < (1 << 13) + 1; off_0 += (1 << 13))
        sum += acc_13(off_0);
    return sum;
}

void main() {
    int off = 0;
    int n = int(adsk_results_pass1_h);
    vec4 sum = vec4(0.);
    if (bool(n & (1 << 0))) {
        sum += acc_0();
        off += (1 << 0);
        n -= (1 << 0);
    }
    if (bool(n & (1 << 1))) {
        sum += acc_1(off);
        off += (1 << 1);
        n -= (1 << 1);
    }
    if (bool(n & (1 << 2))) {
        sum += acc_2(off);
        off += (1 << 2);
        n -= (1 << 2);
    }
    if (bool(n & (1 << 3))) {
        sum += acc_3(off);
        off += (1 << 3);
        n -= (1 << 3);
    }
    if (bool(n & (1 << 4))) {
        sum += acc_4(off);
        off += (1 << 4);
        n -= (1 << 4);
    }
    if (bool(n & (1 << 5))) {
        sum += acc_5(off);
        off += (1 << 5);
        n -= (1 << 5);
    }
    if (bool(n & (1 << 6))) {
        sum += acc_6(off);
        off += (1 << 6);
        n -= (1 << 6);
    }
    if (bool(n & (1 << 7))) {
        sum += acc_7(off);
        off += (1 << 7);
        n -= (1 << 7);
    }
    if (bool(n & (1 << 8))) {
        sum += acc_8(off);
        off += (1 << 8);
        n -= (1 << 8);
    }
    if (bool(n & (1 << 9))) {
        sum += acc_9(off);
        off += (1 << 9);
        n -= (1 << 9);
    }
    if (bool(n & (1 << 10))) {
        sum += acc_10(off);
        off += (1 << 10);
        n -= (1 << 10);
    }
    if (bool(n & (1 << 11))) {
        sum += acc_11(off);
        off += (1 << 11);
        n -= (1 << 11);
    }
    if (bool(n & (1 << 12))) {
        sum += acc_12(off);
        off += (1 << 12);
        n -= (1 << 12);
    }
    if (bool(n & (1 << 13)))
        sum += acc_13(off);
    if (bool(n & (1 << 14)))
        sum = acc_14();
    fragColor = vec4(double(luma) * double(sum.a) / dot(dvec3(double(w_r), 1.lf - (double(w_r) + double(w_b)), double(w_b)), dvec3(sum.rgb)), 0., 0., 0.);
}
