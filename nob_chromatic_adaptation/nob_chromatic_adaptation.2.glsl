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
    bool adsk_degrade;
};

layout (binding = 2) uniform UniformBlock {
    uint mtd;
    bool dbl;
};

layout (binding = 3) uniform sampler2D front;
layout (binding = 4) uniform sampler2D adsk_results_pass1;

void get_data(out dvec4 data[6]) {
    for (uint i = 0; i < 6; ++i) {
        const vec4 f_0 = texelFetch(adsk_results_pass1, ivec2(i, 0), 0);
        const vec4 f_1 = texelFetch(adsk_results_pass1, ivec2(i, 1), 0);
        const uvec4 u_0 = floatBitsToUint(f_0);
        const uvec4 u_1 = floatBitsToUint(f_1);
        data[i] = dvec4(packDouble2x32(u_0.rg), packDouble2x32(u_0.ba), packDouble2x32(u_1.rg), packDouble2x32(u_1.ba));
    }
}

#define GEN_GET_BFD(SCA, VEC3, VEC4, MAT3)                            \
void get_bfd(const VEC4 data[6], out MAT3 a, out SCA b, out MAT3 c) { \
    a = MAT3(data[0].rgb, data[1].rgb, data[2].rgb);                  \
    b = data[0].a;                                                    \
    c = MAT3(data[3].rgb, data[4].rgb, data[5].rgb);                  \
}

GEN_GET_BFD(double, dvec3, dvec4, dmat3)

double log2(double x) {
#ifdef LOG2_CHECK_SIGN
    {
        const uvec2 u = unpackDouble2x32(x);
        if (bool(u.t & 0x80000000u))
            return 0.lf / 0.lf;
    }
#endif
    if (x == 0.lf)
        return -1.lf / 0.lf;
    if (isinf(x))
        return x;
    const double b_0 = 1.lf;
    int e, o;
    double a, b, q, p, b_3, a_3, b_2, a_2, b_1, a_1;
    x = frexp(x, e);
    if (x < .70710678118654752lf) {
        a = 1.lf;
        b = -.5lf;
        q = .16610229006022835lf;
        p = 1.0364939087983456lf;
        b_3 = 1.8878131931525939lf;
        a_3 = 6.1647053704492835lf;
        b_2 = 4.6269859925515529lf;
        a_2 = 8.1477507818138797lf;
        b_1 = 3.8237952410778376lf;
        a_1 = 2.8853900817779268lf;
        o = 1;
    }
    else {
        a = -1.lf;
        b = 1.lf;
        q = .019224138846274291lf;
        p = .11141589065807148lf;
        b_3 = -.3415113237725929lf;
        a_3 = -1.0240843865964922lf;
        b_2 = 1.4203296406447956lf;
        a_2 = 2.2904854500500453lf;
        b_1 = -2.0876435318541187lf;
        a_1 = -1.4426950408889634lf;
        o = 0;
    }
    x = fma(a, x, b);
    q = fma(q, x, b_3);
    p = fma(p, x, a_3);
    q = fma(q, x, b_2);
    p = fma(p, x, a_2);
    q = fma(q, x, b_1);
    p = fma(p, x, a_1);
    q = fma(q, x, b_0);
    p = p / q;
    return fma(p, x, double(e - o));
}

double exp2(double x) {
    if (x < -1074.lf)
        return 0.lf;
    if (1024.lf <= x)
        return 1.lf / 0.lf;
    const double b_3 = -.0039634429645009694lf, a_1 = .69314718055994529lf, b_2 = .051473830172446302lf, b_1 = -.34657359027997263lf, b_0 = 1.lf;
    const int e = int(round(x));
    double q = .00013727074129879lf, p = .00792688592900185lf;
    x -= double(e);
    q = fma(q, x, b_3);
    p = fma(p, x * x, a_1);
    q = fma(q, x, b_2);
    q = fma(q, x, b_1);
    q = fma(q, x, b_0);
    p = p / q;
    x = fma(p, x, 1.lf);
    return ldexp(x, e);
}

double pow(const double x, const double y) {
    return exp2(log2(x) * y);
}

double sign0(const double x) {
    const uvec2 u = unpackDouble2x32(x);
    return bool(u.t & 0x80000000u) ? -1.lf : 1.lf;
}

#define GEN_BFD(SCA, VEC3, VEC4, MAT3)                                                                               \
VEC3 bfd(const VEC4 data[6], VEC3 col) {                                                                             \
    const MAT3 bfd_fwd = MAT3(.8951lf, -.7502lf, .0389lf, .2664lf, 1.7135lf, -.0685lf, -.1614lf, .0367lf, 1.0296lf); \
    MAT3 a, c;                                                                                                       \
    SCA b;                                                                                                           \
    get_bfd(data, a, b, c);                                                                                          \
    col = a * col;                                                                                                   \
    const SCA y = col.y;                                                                                             \
    col = bfd_fwd * col;                                                                                             \
    if (y != SCA(0.lf)) {                                                                                            \
        const SCA tmp = col.z / y;                                                                                   \
        col.z = sign0(tmp) * (y * pow(abs(tmp), b));                                                                 \
    }                                                                                                                \
    return c * col;                                                                                                  \
}

GEN_BFD(double, dvec3, dvec4, dmat3)

#define GEN_GET_CAT16(SCA, VEC3, VEC4, MAT3)                                                                                  \
void get_cat16(const VEC4 data[6], out MAT3 a, out MAT3 b, out SCA c_0, out SCA c_1, out SCA c_2, out SCA c_3, out SCA c_4) { \
    a = MAT3(data[0].rgb, data[1].rgb, data[2].rgb);                                                                          \
    b = MAT3(data[3].rgb, data[4].rgb, data[5].rgb);                                                                          \
    c_0 = data[0].a;                                                                                                          \
    c_1 = data[1].a;                                                                                                          \
    c_2 = data[2].a;                                                                                                          \
    c_3 = data[3].a;                                                                                                          \
    c_4 = data[4].a;                                                                                                          \
}

GEN_GET_CAT16(double, dvec3, dvec4, dmat3)

#define GEN_VPOW(SCA, VEC3)                             \
VEC3 vpow(const VEC3 x, const SCA y) {                  \
    return VEC3(pow(x.r, y), pow(x.g, y), pow(x.b, y)); \
}

GEN_VPOW(double, dvec3)

dvec3 sign0(const dvec3 x) {
    const uvec2 u_0 = unpackDouble2x32(x.x), u_1 = unpackDouble2x32(x.y), u_2 = unpackDouble2x32(x.z);
    const uvec3 u = uvec3(u_0.t, u_1.t, u_2.t);
    return mix(dvec3(-1.lf), dvec3(1.lf), equal(u & uvec3(0x80000000u), uvec3(0)));
}

#define GEN_CAT16_PACR(SCA, VEC3)                \
VEC3 cat16_pacr(const VEC3 col, const SCA c) {   \
    const VEC3 tmp = vpow(abs(col), SCA(.42lf)); \
    return sign0(col) * (tmp / (tmp + c));       \
}

GEN_CAT16_PACR(double, dvec3)

#define GEN_CAT16_PACR_INV(SCA, VEC3)                                                  \
VEC3 cat16_pacr_inv(const VEC3 col, const SCA c) {                                     \
    const VEC3 tmp = abs(col);                                                         \
    return sign0(col) * (c * vpow(tmp / (SCA(1.lf) - tmp), SCA(2.380952380952381lf))); \
}

GEN_CAT16_PACR_INV(double, dvec3)

#define GEN_CAT16(SCA, VEC2, VEC3, VEC4, MAT3)                                                                                                                                                                                             \
VEC3 cat16(const VEC4 data[6], VEC3 col) {                                                                                                                                                                                                 \
    MAT3 a, b;                                                                                                                                                                                                                             \
    SCA c_0, c_1, c_2, c_3, c_4;                                                                                                                                                                                                           \
    get_cat16(data, a, b, c_0, c_1, c_2, c_3, c_4);                                                                                                                                                                                        \
    col = a * col;                                                                                                                                                                                                                         \
    col = cat16_pacr(col, c_0);                                                                                                                                                                                                            \
    SCA p_0 = fma(SCA(2.lf), col.r, fma(SCA(.05lf), col.b, col.g));                                                                                                                                                                        \
    const SCA s = sign0(p_0);                                                                                                                                                                                                              \
    col *= s;                                                                                                                                                                                                                              \
    p_0 = pow(abs(p_0), c_1) * c_2;                                                                                                                                                                                                        \
    const SCA p_1 = c_3 * (fma(SCA(1.05lf), col.b, col.r + col.g) + SCA(.0007625lf));                                                                                                                                                      \
    const SCA p_2 = p_1 + (col.r - col.b);                                                                                                                                                                                                 \
    {                                                                                                                                                                                                                                      \
        const MAT3 m_0 = MAT3(2.625e-4lf, -5.e-4lf, -5.e-4lf, -2.5e-4lf, 5.125e-4lf, -2.5e-4lf, -1.25e-5lf, -1.25e-5lf, 7.5e-4lf);                                                                                                         \
        const MAT3 m_1 = MAT3(.67213114754098361lf, -.32786885245901639lf, -.32786885245901639lf, -.32786885245901639lf, .67213114754098361lf, -.32786885245901639lf, -.34426229508196721lf, -.34426229508196721lf, .65573770491803279lf); \
        col = fma(VEC3(.32786885245901639lf), VEC3(p_0 * p_1), fma(VEC3(p_0), m_1 * col, m_0 * col));                                                                                                                                      \
    }                                                                                                                                                                                                                                      \
    col /= p_2;                                                                                                                                                                                                                            \
    col = cat16_pacr_inv(s * col, c_4);                                                                                                                                                                                                    \
    return b * col;                                                                                                                                                                                                                        \
}

GEN_CAT16(double, dvec2, dvec3, dvec4, dmat3)

#define GEN_GET_A(VEC4, MAT3)                        \
void get_a(const VEC4 data[6], out MAT3 a) {         \
    a = MAT3(data[0].rgb, data[1].rgb, data[2].rgb); \
}

GEN_GET_A(dvec4, dmat3)

#define GEN_LIN(VEC3, VEC4, MAT3)              \
VEC3 lin(const VEC4 data[6], const VEC3 col) { \
    MAT3 a;                                    \
    get_a(data, a);                            \
    return a * col;                            \
}

GEN_LIN(dvec3, dvec4, dmat3)

void get_data(out vec4 data[6]) {
    for (uint i = 0; i < 6; ++i)
        data[i] = texelFetch(adsk_results_pass1, ivec2(i, 0), 0);
}

GEN_GET_BFD(float, vec3, vec4, mat3)

float sign0(float x) {
    const uint u = floatBitsToUint(x);
    return bool(u & 0x80000000u) ? -1. : 1.;
}

GEN_BFD(float, vec3, vec4, mat3)

GEN_GET_CAT16(float, vec3, vec4, mat3)

GEN_VPOW(float, vec3)

vec3 sign0(vec3 x) {
    const uvec3 u = floatBitsToUint(x);
    return mix(vec3(-1.), vec3(1.), equal(u & uvec3(0x80000000u), uvec3(0)));
}

GEN_CAT16_PACR(float, vec3)

GEN_CAT16_PACR_INV(float, vec3)

GEN_CAT16(float, vec2, vec3, vec4, mat3)

GEN_GET_A(vec4, mat3)

GEN_LIN(vec3, vec4, mat3)

void main() {
    vec3 col = texelFetch(front, ivec2(gl_FragCoord.xy), 0).rgb;
    if (!adsk_degrade && dbl) {
        dvec4 data[6];
        get_data(data);
        dvec3 dcol = col;
        switch (mtd) {
        case 2:
            dcol = bfd(data, dcol);
            break;
        case 5:
            dcol = cat16(data, dcol);
            break;
        default:
            dcol = lin(data, dcol);
        }
        fragColor = vec4(dcol, 1.);
        return;
    }
    vec4 data[6];
    get_data(data);
    switch (mtd) {
    case 2:
        col = bfd(data, col);
        break;
    case 5:
        col = cat16(data, col);
        break;
    default:
        col = lin(data, col);
    }
    fragColor = vec4(col, 1.);
}
