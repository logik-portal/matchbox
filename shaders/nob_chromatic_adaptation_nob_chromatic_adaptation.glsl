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

layout (binding = 1) uniform UniformBlock {
    uint method;
    uint source_cs;
    uint source_type;
    uint source_illum;
    float source_cct;
    float source_tint;
    bool source_cct_d;
    vec2 source_coord;
    vec3 source_colour;
    uint target_cs;
    uint target_type;
    uint target_illum;
    float target_cct;
    float target_tint;
    bool target_cct_d;
    vec2 target_coord;
    vec3 target_colour;
    float source_s;
    float source_l_a;
    float source_n;
    float target_s;
    float target_l_a;
    float target_n;
};

layout (binding = 3) uniform sampler2D front;

const mat3 acescg_to_xyz  = mat3(.6624542,      .2722287,    -.0055746,   .1340042,  .6740818,      .0040607,   .1561877,     .0536895,    1.0103391);
const mat3 aces_to_xyz    = mat3(.9525523959,   .3439664498,  0.,         0.,        .7281660966,   0.,         .0000936786, -.0721325464, 1.0088251844);
const mat3 rec709_to_xyz  = mat3(.4123908,      .212639,      .0193308,   .3575843,  .7151687,      .1191948,   .1804808,     .0721923,    .9505322);
const mat3 rec2020_to_xyz = mat3(.636958,       .2627002,     0.,         .1446169,  .6779981,      .0280727,   .168881,      .0593017,    1.0609851);
const mat3 p3d65_to_xyz   = mat3(.4865709,      .2289746,     0.,         .2656677,  .6917385,      .0451134,   .1982173,     .0792869,    1.0439444);
const mat3 xyz_to_lms     = mat3(.7328,        -.7036,        .003,       .4296,     1.6975,        .0136,     -.1624,        .0061,       .9834);
const mat3 lms_to_hpe     = mat3(.740979,       .285353,     -.00962761,  .218025,   .624202,      -.00569803,  .0410057,     .0904451,    1.01533);
const mat3 hpe_to_lms     = mat3(1.55915,      -.714327,      .0107755,  -.544723,   1.85031,       .00521877, -.0144453,    -.135976,     .984006);
const mat3 lms_to_xyz     = mat3(1.09612,       .454369,     -.00962761, -.278869,   .473533,      -.00569803,  .182745,      .0720978,    1.01533);
const mat3 xyz_to_brdfrd  = mat3(.8951,        -.7502,        .0389,      .2664,     1.7135,       -.0685,     -.1614,        .0367,       1.0296);
const mat3 brdfrd_to_xyz  = mat3(.9869929,      .4323053,    -.0085287,  -.1470543,  .5183603,      .0400428,   .1599627,     .0492912,    .9684867);
const mat3 xyz_to_vkries  = mat3(.40024,       -.2263,        0.,         .7076,     1.16532,       0.,        -.08081,       .0457,       .91822);
const mat3 vkries_to_xyz  = mat3(1.8599364,     .3611914,     0.,        -1.1293816, .6388125,      0.,         .2198974,    -.0000064,    1.0890636);
const mat3 xyz_to_acescg  = mat3(1.6410234,    -.6636629,     .0117219,  -.3248033,  1.6153316,    -.0082844,  -.2364247,     .0167563,    .9883949);
const mat3 xyz_to_aces    = mat3(1.0498110175, -.4959030231,  0.,         0.,        1.3733130458,  0.,        -.0000974845,  .0982400361, .9912520182);
const mat3 xyz_to_rec709  = mat3(3.2409699,    -.9692436,     .0556301,  -1.5373832, 1.8759675,    -.203977,   -.4986108,     .0415551,    1.0569715);
const mat3 xyz_to_rec2020 = mat3(1.7166512,    -.6666844,     .0176399,  -.3556708,  1.6164812,    -.0427706,  -.2533663,     .0157685,    .9421031);
const mat3 xyz_to_p3d65   = mat3(2.4934969,    -.829489,      .0358458,  -.9313836,  1.7626641,    -.0761724,  -.4027108,     .0236247,    .9568845);

const mat3x2 hpe_to_ab = mat3x2(1., .111111111111111, -1.090909090909091, .111111111111111, .090909090909091, -.222222222222222);
const mat3 t_ab_to_l_hpe = mat3(.3278688524590164, .3278688524590164, .3278688524590164, .4782608695652174, -.4782608695652174, 0., 1.744832501781896, 1.353528153955809, -2.950819672131148);

const vec2 aces_white = vec2(.32168,           .33767);
const vec2 hd_white   = vec2(.3127,            .329);
const vec2 dci_white  = vec2(.314,             .351);
const vec2 e_e_white  = vec2(.333333333333333, .333333333333333);

vec3 in_to_xyz(vec3 colour) {
    switch (source_cs) {
    case 0:
        return acescg_to_xyz * colour;
    case 1:
        return aces_to_xyz * colour;
    case 2:
        return rec709_to_xyz * colour;
    case 3:
        return rec2020_to_xyz * colour;
    case 4:
        return p3d65_to_xyz * colour;
    }
    return colour;
}

vec2 get_xy_from_cs(uint idx) {
    switch (idx) {
    case 0:
    case 1:
        return aces_white;
    case 2:
    case 3:
    case 4:
        return hd_white;
    }
    return e_e_white;
}

vec2 get_xy_from_illuminant(uint idx) {
    switch (idx) {
    case 0:
        return aces_white;
    case 1:
        return hd_white;
    case 2:
        return dci_white;
    }
    return e_e_white;
}

vec2 get_xy_from_temp(float cct, float tint, bool temperature_shift) {
    float denom, denom2;
    vec2 xy, dxy_dcct, uv, duv_dcct, tint_vec;
    mat2 jacobi;
    if (temperature_shift)
        cct *= 1.000556328233658;
    cct = clamp(cct, 4000., 25000.);
    if (cct < 7000) {
        xy.x = ((-4.607e9 / cct + 2.9678e6) / cct + .09911e3) / cct + .244063;
        dxy_dcct.x = ((13.821e9 / cct - 5.9356e6) / cct - .09911e3) / (cct * cct);
    }
    else {
        xy.x = ((-2.0064e9 / cct + 1.9018e6) / cct + .24748e3) / cct + .23704;
        dxy_dcct.x = ((6.0192e9 / cct - 3.8036) / cct - .24748e3) / (cct * cct);
    }
    xy.y = (-3. * xy.x + 2.87) * xy.x - .275;
    dxy_dcct.y = (-6. * xy.x + 2.87) * dxy_dcct.x;
    denom = 1. / (-2. * xy.x + 12. * xy.y + 3.);
    denom2 = denom * denom;
    uv = vec2(4. * xy.x,  6. * xy.y) * denom;
    jacobi = mat2(4. * denom + 8. * xy.x * denom2, 12. * xy.y * denom2, -48. * xy.x * denom2, 6. * denom - 72. * xy.y * denom2);
    duv_dcct = jacobi * dxy_dcct;
    tint_vec = vec2(duv_dcct.y, -duv_dcct.x);
    tint_vec = normalize(tint_vec);
    uv += tint_vec * tint;
    denom = 1. / (uv.x - 4. * uv.y + 2.);
    return vec2(1.5 * uv.x, uv.y) * denom;
}

vec2 get_in_xy(void) {
    vec3 xyz;
    switch (source_type) {
    case 0:
        return get_xy_from_cs(source_cs);
    case 1:
        return get_xy_from_illuminant(source_illum);
    case 2:
        return get_xy_from_temp(source_cct, source_tint, source_cct_d);
    case 3:
        return source_coord;
    }
    xyz = in_to_xyz(source_colour);
    return vec2(xyz.x, xyz.y) / (xyz.x + xyz.y + xyz.z);
}

vec2 get_out_xy(void) {
    vec3 xyz;
    switch (target_type) {
    case 0:
        return get_xy_from_cs(target_cs);
    case 1:
        return get_xy_from_illuminant(target_illum);
    case 2:
        return get_xy_from_temp(target_cct, target_tint, target_cct_d);
    case 3:
        return target_coord;
    }
    xyz = in_to_xyz(target_colour);
    return vec2(xyz.x, xyz.y) / (xyz.x + xyz.y + xyz.z);
}

vec3 xy_to_xyz(vec2 xy) {
    return vec3(xy.x / xy.y, 1., (1. - (xy.x + xy.y)) / xy.y);
}

vec3 get_cie_f_c_n_c(float s) {
    return vec3(1. -.1 * s, (.0175 * s - .1175) * s + .69, 1. - .05 * s * s);
}

vec3 cat02_fwd(vec3 colour, vec2 in_xy, float s, float l_a, float n) {
    float d, k, fl, n_b, z, a, a_w, j, l, h, t, ch;
    vec2 ab;
    vec3 in_tri = xy_to_xyz(in_xy);
    vec3 f_c_n_c = get_cie_f_c_n_c(s);
    in_tri = xyz_to_lms * in_tri;
    colour = xyz_to_lms * colour;
    d = f_c_n_c.s * (1. - .277777777777778 * exp(-.010869565217391 * (l_a + 42.)));
    colour *= d / in_tri + (1. - d);
    in_tri = d + (1. - d) * in_tri;
    colour = lms_to_hpe * colour;
    in_tri = lms_to_hpe * in_tri;
    k = .2 / (l_a + .2);
    k *= k;
    k *= k;
    fl = 1. - k;
    fl = .2 * k * (5. * l_a) + .1 * fl * fl * pow(5. * l_a, .333333333333333);
    colour = sign(colour) * pow(fl * abs(colour), vec3(.42));
    in_tri = sign(in_tri) * pow(fl * abs(in_tri), vec3(.42));
    colour = 4. * colour / (27.13 + colour) + .001;
    in_tri = 4. * in_tri / (27.13 + in_tri) + .001;
    n_b = .725 * pow(n, -.2);
    z = 1.48 + sqrt(n);
    a = (dot(vec3(2., 1., .05), colour) - .00305) * n_b;
    a_w = (dot(vec3(2., 1., .05), in_tri) - .00305) * n_b;
    j = sign(a) * pow(abs(a) / a_w, f_c_n_c.t * z);
    ab = hpe_to_ab * colour;
    l = length(ab);
    h = atan(ab.y, ab.x);
    t = 9.615384615384615 * f_c_n_c.p * n_b * (cos(h + 2.) + 3.8) * l / dot(vec3(1., 1., 1.05), colour);
    ch = pow(t, .9) * sign(j) * sqrt(abs(j)) * pow(1.64 - pow(.29, n), .73);
    return vec3(j, ch, h);
}

vec3 cat02_bwd(vec3 colour, vec2 out_xy, float s, float l_a, float n) {
    float j = colour.r, ch = colour.g, h = colour.b, d, k, fl, n_b, z, a_w, a, t, e;
    vec2 ab;
    vec3 out_tri = xy_to_xyz(out_xy), out_tri_1;
    vec3 f_c_n_c = get_cie_f_c_n_c(s);
    out_tri_1 = out_tri = xyz_to_lms * out_tri;
    d = f_c_n_c.s * (1. - .277777777777778 * exp(-.010869565217391 * (l_a + 42.)));
    out_tri_1 = d + (1. - d) * out_tri_1;
    out_tri_1 = lms_to_hpe * out_tri_1;
    k = .2 / (l_a + .2);
    k *= k;
    k *= k;
    fl = 1. - k;
    fl = .2 * k * (5. * l_a) + .1 * fl * fl * pow(5. * l_a, .333333333333333);
    out_tri_1 = sign(out_tri_1) * pow(fl * abs(out_tri_1), vec3(.42));
    out_tri_1 = 4. * out_tri_1 / (27.13 + out_tri_1) + .001;
    n_b = .725 * pow(n, -.2);
    z = 1.48 + sqrt(n);
    a_w = (dot(vec3(2., 1., .05), out_tri_1) - .00305) * n_b;
    a = a_w * sign(j) * pow(abs(j), 1. / (f_c_n_c.t * z)) / n_b + .00305;
    t = pow(sign(j) * sqrt(abs(j)) * pow(1.64 - pow(.29, n), .73) / ch, 1.111111111111111);
    t = 9.615384615384615 * f_c_n_c.p * n_b * (cos(h + 2.) + 3.8) * t;
    ab = vec2(cos(h), sin(h));
    colour = t_ab_to_l_hpe * vec3(t, ab);
    colour *= a / dot(vec3(2., 1., .05), colour);
    colour = (27.13 * colour - .02713) / (4.001 - colour);
    colour = sign(colour) * pow(abs(colour), vec3(2.380952380952381)) / fl;
    colour = hpe_to_lms * colour;
    colour /= d / out_tri + (1. - d);
    return lms_to_xyz * colour;
}

vec3 cat02_smp(vec3 colour, vec2 in_xy, vec2 out_xy) {
    vec3 out_tri = xy_to_xyz(out_xy);
    vec3 in_tri = xy_to_xyz(in_xy);
    out_tri = xyz_to_lms * out_tri;
    in_tri = xyz_to_lms * in_tri;
    colour = xyz_to_lms * colour;
    colour *= out_tri / in_tri;
    return lms_to_xyz * colour;
}

vec3 bradford(vec3 colour, vec2 in_xy, vec2 out_xy) {
    vec3 out_tri = xy_to_xyz(out_xy);
    vec3 in_tri = xy_to_xyz(in_xy);
    out_tri = xyz_to_brdfrd * out_tri;
    in_tri = xyz_to_brdfrd * in_tri;
    colour = xyz_to_brdfrd * colour;
    colour *= out_tri / in_tri;
    return brdfrd_to_xyz * colour;
}

vec3 von_kries(vec3 colour, vec2 in_xy, vec2 out_xy) {
    vec3 out_tri = xy_to_xyz(out_xy);
    vec3 in_tri = xy_to_xyz(in_xy);
    out_tri = xyz_to_vkries * out_tri;
    in_tri = xyz_to_vkries * in_tri;
    colour = xyz_to_vkries * colour;
    colour *= out_tri / in_tri;
    return vkries_to_xyz * colour;
}

vec3 xyz_to_out(vec3 colour) {
    switch (target_cs) {
    case 0:
        return xyz_to_acescg * colour;
    case 1:
        return xyz_to_aces * colour;
    case 2:
        return xyz_to_rec709 * colour;
    case 3:
        return xyz_to_rec2020 * colour;
    case 4:
        return xyz_to_p3d65 * colour;
    }
    return colour;
}

void main() {
    vec2 in_xy = get_in_xy();
    vec2 out_xy = get_out_xy();
    vec3 colour = in_to_xyz(texelFetch(front, ivec2(gl_FragCoord.xy), 0).rgb);
    switch (method) {
    case 0:
        colour = cat02_fwd(colour, in_xy, source_s, source_l_a, source_n);
        colour = cat02_bwd(colour, out_xy, target_s, target_l_a, target_n);
        colour = mix(colour, vec3(0., 0., 0.), isnan(colour));
        break;
    case 1:
        colour = cat02_smp(colour, in_xy, out_xy);
        break;
    case 2:
        colour = bradford(colour, in_xy, out_xy);
        break;
    default:
        colour = von_kries(colour, in_xy, out_xy);
    }
    fragColor = vec4(xyz_to_out(colour), 0.);
}
