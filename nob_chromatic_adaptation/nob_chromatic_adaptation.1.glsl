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
    uint spr;
    vec3 spx;
    vec3 spy;
    uint sil;
    uint sis;
    float sit;
    float sitt;
    bool sitd;
    vec2 sixy;
    uint tpr;
    vec3 tpx;
    vec3 tpy;
    uint til;
    uint tis;
    float tit;
    float titt;
    bool titd;
    vec2 tixy;
    uint fca;
    vec3 svc;
    vec3 tvc;
    uint osil;
    uint osis;
    float osit;
    float ositt;
    bool ositd;
    vec2 osixy;
    vec3 osic;
    uint otil;
    uint otis;
    float otit;
    float otitt;
    bool otitd;
    vec2 otixy;
    vec3 otic;
};

const dvec3 whts[] = {
    dvec3(.9526460745698463lf, 1.lf, 1.0088251843515859lf),
    dvec3(.9642lf, 1.lf, .824lf),
    dvec3(.95045592705167173lf, 1.lf, 1.0890577507598784lf),
    dvec3(.89458689458689459lf, 1.lf, .95441595441595442lf),
    dvec3(1.lf, 1.lf, 1.lf)
};

const dmat3 raws_inv[] = {
    dmat3(.44673368886166575lf, -.44736303171126306lf, .00062934284959731201lf, -.088420783982139251lf, 1.0888655716749113lf, -.00044478769277203355lf, -.064361591399853972lf, .011295148436407699lf, .053066442963446272lf),
    dmat3(.36109976861303934lf, -.36109976861303934lf, 0.lf, 0.lf, 1.lf, 0.lf, -3.353141133002501e-5lf, .071535063587019504lf, -.071501532175689479lf),
    dmat3(.6891566265060241lf, -.69317269076305221lf, .0040160642570281124lf, -.32690763052208835lf, 1.3416331994645248lf, -.014725568942436412lf, -.10602409638554217lf, .029718875502008032lf, .076305220883534137lf),
    dmat3(.45096463102944543lf, -.45201070485423604lf, .0010460738247906111lf, -.093434790304271794lf, 1.0959711610849285lf, -.0025363707806566871lf, -.066559375833366766lf, .010691043652488713lf, .055868332180878053lf),
    dmat3(.57094736842105263lf, -.57378947368421053lf, .0028421052631578947lf, -.21326315789473684lf, 1.2193026315789474lf, -.0060394736842105263lf, -.092210526315789474lf, .016342105263157895lf, .075868421052631579lf),
    dmat3(.38413182508863751lf, -.38413182508863751lf, 0.lf, -.063783082897180483lf, 1.0637830828971805lf, 0.lf, -.042966601716772713lf, .076024452956442134lf, -.033057851239669421lf),
    dmat3(.40504328165716568lf, -.40985921728407209lf, .0048159356269064044lf, -.050894854248078012lf, 1.0880301561411178lf, -.037135301893039778lf, -.043511773349426323lf, .13268543389865054lf, -.089173660549224215lf),
    dmat3(.40057716948385573lf, -.40128660207354173lf, .00070943258968600543lf, -.10926855621007111lf, 1.111233099684936lf, -.0019645434748649178lf, -.054048914051041843lf, -.013431675489666346lf, .067480589540708189lf)
};

const dmat3 raws[] = {
    dmat3(2.4334470989761092lf, 1.lf, -.020477815699658703lf, .19879518072289157lf, 1.lf, .0060240963855421687lf, 2.9090909090909091lf, 1.lf, 18.818181818181818lf),
    dmat3(2.7693177534866189lf, 1.lf, 0.lf, 0.lf, 1.lf, 0.lf, -.0012987012987012987lf, 1.lf, -13.985714285714286lf),
    dmat3(1.9393939393939394lf, 1.lf, .090909090909090909lf, .5lf, 1.lf, .16666666666666667lf, 2.5lf, 1.lf, 13.166666666666667lf),
    dmat3(2.4246575342465753lf, 1.lf, 0.lf, .21329987452948557lf, 1.lf, .041405269761606023lf, 2.8478260869565217lf, 1.lf, 17.891304347826087lf),
    dmat3(2.125lf, 1.lf, 0.lf, .38405797101449275lf, 1.lf, .065217391304347826lf, 2.5lf, 1.lf, 13.166666666666667lf),
    dmat3(2.7693177534866189lf, 1.lf, 0.lf, .16604477611940299lf, 1.lf, 0.lf, -3.2175324675324675lf, 1.lf, -30.25lf),
    dmat3(2.5646682201983218lf, 1.lf, -.27792988072426566lf, .081389215753209183lf, 1.lf, -.4120424847757086lf, -1.1303124519736609lf, 1.lf, -11.691555639622173lf),
    dmat3(2.7691756812785044lf, 1.lf, 0.lf, .27631394752399364lf, 1.lf, .026207793493560636lf, 2.2729839604252278lf, 1.lf, 14.824292754200607lf)
};

const dmat3 bfd_fwd = dmat3(.8951lf, -.7502lf, .0389lf, .2664lf, 1.7135lf, -.0685lf, -.1614lf, .0367lf, 1.0296lf);
const dmat3 bfd_bwd = dmat3(.98699290546671219lf, .43230526972339451lf, -.0085286645751773312lf, -.1470542564209901lf, .51836027153677754lf, .040042821654084864lf, .15996265166373124lf, .049291228212855612lf, .96848669578754998lf);

const dmat3 cat16_fwd = dmat3(.401288lf, -.250268lf, -.002079lf, .650173lf, 1.204414lf, .048952lf, -.051461lf, .045854lf, .953127lf);
const dmat3 cat16_fwd_T = dmat3(.401288lf, .650173lf, -.051461lf, -.250268lf, 1.204414lf, .045854lf, -.002079lf, .048952lf, .953127lf);
const dmat3 cat16_bwd = dmat3(1.8620678550872327lf, .38752654323613716lf, -.015841498849333855lf, -1.0112546305316844lf, .62144744193147536lf, -.034122938028515564lf, .14918677544445172lf, -.0089739851676125183lf, 1.0499644368778494lf);

dvec3 xy_to_xyz(const dvec2 xy) {
    return dvec3(xy.x / xy.y, 1.lf, (1.lf - (xy.x + xy.y)) / xy.y);
}

dvec3 gen_wht_it(const float it, const float itt, const bool itd) {
    double dit = it;
    if (itd) {
        dit *= 1.000540248611915lf;
        dit = min(25000.lf, dit);
    }
    else
        dit = max(4000.lf, dit);
    dvec2 xy;
    if (7000.lf < dit) {
        dit = 1.lf / dit;
        xy.x = fma(fma(fma(-2.0064e9lf, dit, 1901800.lf), dit, 247.48lf), dit, .23704lf);
    }
    else
        {
        dit = 1.lf / dit;
        xy.x = fma(fma(fma(-4.607e9lf, dit, 2967800.lf), dit, 99.11lf), dit, .244063lf);
    }
    xy.y = fma(fma(-3.lf, xy.x, 2.87lf), xy.x, -.275lf);
    dvec2 uv;
    {
        dvec2 duv_dx;
        {
            const double denom = fma(-6.lf, xy.y, xy.x) - 1.5lf;
            uv = dvec2(-2. * xy.x, -4.5 * xy.y) / denom;
            {
                const dmat2 j = dmat2(-2.lf - uv.x, -uv.y, 6.lf * uv.x, fma(6.lf, uv.y, -4.5lf));
                duv_dx = (j * dvec2(1.lf, fma(-6.lf, xy.x, 2.87lf))) / denom;
            }
        }
        const dvec2 tint_vec = normalize(dvec2(duv_dx.y, -duv_dx.x));
        uv += tint_vec * double(itt);
    }
    const double denom = fma(-.375lf, uv.x, uv.y) - .75lf;
    return xy_to_xyz(dvec2(-.5625lf * uv.x, -.25lf * uv.y) / denom);
}

dvec3 gen_wht(const uint il, const uint pr, const uint is, const float it, const float itt, const bool itd, const vec2 ixy) {
    switch (il) {
    case 0:
        if (pr < 2)
            return whts[0];
        if (pr == 8)
            return whts[4];
        return whts[2];
    case 1:
        return whts[is];
    case 2:
        return gen_wht_it(it, itt, itd);
    default:
        return xy_to_xyz(ixy);
    }
}

dmat3 gen_raw(const vec3 px, const vec3 py) {
    const double xr = px.r, xg = px.g, xb = px.b, yr = py.r, yg = py.g, yb = py.b;
    return dmat3(xr / yr, 1.lf, (1.lf - (xr + yr)) / yr, xg / yg, 1.lf, (1.lf - (xg + yg)) / yg, xb / yb, 1.lf, (1.lf - (xb + yb)) / yb);
}

dmat3 gen_mat(const uint pr, const vec3 px, const vec3 py, const dvec3 wht) {
    if (pr == 8)
        return dmat3(1.lf);
    dmat3 raw_inv, raw;
    if (pr < 8) {
        raw_inv = raws_inv[pr];
        raw = raws[pr];
    }
    else {
        raw = gen_raw(px, py);
        raw_inv = inverse(raw);
    }
    const dvec3 s = raw_inv * wht;
    raw[0] *= s.r;
    raw[1] *= s.g;
    raw[2] *= s.b;
    return raw;
}

void gen_mat(const uint pr, const vec3 px, const vec3 py, const dvec3 wht, out dmat3 mat, out dmat3 mat_inv) {
    if (pr == 8) {
        mat = dmat3(1.lf);
        mat_inv = dmat3(1.lf);
        return;
    }
    dmat3 raw_inv, raw;
    if (pr < 8) {
        raw_inv = raws_inv[pr];
        raw = raws[pr];
    }
    else {
        raw = gen_raw(px, py);
        raw_inv = inverse(raw);
    }
    const dvec3 s = raw_inv * wht;
    raw[0] *= s.r;
    raw[1] *= s.g;
    raw[2] *= s.b;
    mat = raw;
    raw_inv = transpose(raw_inv);
    raw_inv[0] /= s.r;
    raw_inv[1] /= s.g;
    raw_inv[2] /= s.b;
    mat_inv = transpose(raw_inv);
}

dvec3 gen_owht(const uint il, const dvec3 wht, const uint is, const float it, const float itt, const bool itd, const vec2 ixy, const vec3 ic, const dmat3 mat) {
    switch (il) {
    case 0:
        return wht;
    case 1:
        return whts[is];
    case 2:
        return gen_wht_it(it, itt, itd);
    case 3:
        return xy_to_xyz(ixy);
    default:
        const dvec3 c = mat * dvec3(ic);
        return c / c.y;
    }
}

double log2(double x) {
#ifdef LOG2_CHECK_SIGN
    {
        const uvec2 u = unpackDouble2x32(x);
        if (bool(u.t & 0x80000000u))
            return 0.lf / 0.lf;
    }
#endif
    if (isinf(x))
        return x;
    if (x == 0.lf)
        return -1.lf / 0.lf;
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

void gen_bfd(const dvec3 oswht, const dvec3 otwht, const dmat3 smat, const dmat3 tmat_inv, out dvec4 data[6]) {
    const dvec3 aswht = bfd_fwd * oswht;
    const dvec3 atwht = bfd_fwd * otwht;
    const double b = pow(aswht.z / atwht.z, .0834lf);
    dmat3 tmp = dmat3(bfd_bwd[0] * atwht.x / aswht.x, bfd_bwd[1] * atwht.y / aswht.y, bfd_bwd[2] * atwht.z * (sign0(aswht.z) * pow(abs(aswht.z), -b)));
    tmp = tmat_inv * tmp;
    data[0] = dvec4(smat[0], b);
    data[1].rgb = smat[1];
    data[2].rgb = smat[2];
    data[3].rgb = tmp[0];
    data[4].rgb = tmp[1];
    data[5].rgb = tmp[2];
}

dvec2 gen_cat16_F_c(const double s) {
    if (s < 0.lf)
        return mix(dvec2(.9lf, .59lf), dvec2(.8lf, .525lf), -s);
    return mix(dvec2(.9lf, .59lf), dvec2(1.lf, .69f), s);
}

double cbrt(const double x) {
    const double a_0 = .4943965559184235lf, a_1 = .69443633473213166lf, a_2 = -.1893976703607558lf;
    const double scale[] = {
        .62996052494743658lf,
        .79370052598409974lf,
        1.lf,
        1.2599210498948732lf,
        1.5874010519681994lf
    };
    int e;
    const double m = frexp(x, e);
    double y = fma(a_2, m, a_1);
    y = fma(y, m, a_0);
    const double t = y * y * y;
    y *= fma(2., m, t) / fma(2., t, m);
    const int e_3 = e / 3;
    e -= 3 * e_3;
    y = ldexp(y * scale[e + 2], e_3);
    y = fma(2.lf, y, x / (y * y)) * .33333333333333333lf;
    return y;
}

double qirt(const double x) {
    const double a_0 = .67111287225653074lf, a_1 = .47116295790072318lf, a_2 = -.14273569445441768lf;
    const double scale[] = {
        .57434917749851750lf,
        .65975395538644713lf,
        .75785828325519904lf,
        .87055056329612414lf,
        1.lf,
        1.148698354997035lf,
        1.3195079107728943lf,
        1.5157165665103981lf,
        1.7411011265922483lf
    };
    int e;
    const double m = frexp(x, e);
    double y = fma(a_2, m, a_1);
    y = fma(y, m, a_0);
    double t = y * y;
    t *= (t * y);
    y *= fma(1.5lf, m, t) / fma(1.5lf, t, m);
    const int e_5 = e / 5;
    e -= 5 * e_5;
    y = ldexp(y * scale[e + 4], e_5);
    t = y * y;
    t *= t;
    y = fma(4.lf, y, x / t) * .2lf;
    return y;
}

dvec3 vpow(const dvec3 x, const double y) {
    return dvec3(pow(x.r, y), pow(x.g, y), pow(x.b, y));
}

dvec3 sign0(const dvec3 x) {
    const uvec2 u_0 = unpackDouble2x32(x.x), u_1 = unpackDouble2x32(x.y), u_2 = unpackDouble2x32(x.z);
    const uvec3 u = uvec3(u_0.t, u_1.t, u_2.t);
    return mix(dvec3(-1.lf), dvec3(1.lf), equal(u & uvec3(0x80000000u), uvec3(0)));
}

dvec3 cat16_pacr(const dvec3 col, const double c) {
    const dvec3 tmp = vpow(abs(col), .42lf);
    return sign0(col) * (tmp / (tmp + c));
}

void gen_cat16(const dvec3 oswht, const dvec3 otwht, const dmat3 smat, const dmat3 tmat_inv, out dvec4 data[6]) {
    const dvec2 sF_c = gen_cat16_F_c(svc.s), tF_c = gen_cat16_F_c(tvc.s);
    const double sL_A = svc.p, tL_A = tvc.p;
    dvec3 sw = cat16_fwd * oswht, tw = cat16_fwd * otwht, d3, d3_inv;
    if (bool(fca % 2)) {
        d3 = dvec3(1.lf) / sw;
        sw = dvec3(1.lf);
    }
    else {
        const double d = fma(sF_c.s, -exp2(fma(-.015681467835749602lf, sL_A, -2.5066185556564333lf)), sF_c.s);
        d3 = mix(dvec3(1.lf), dvec3(1.lf) / sw, d);
        sw = mix(sw, dvec3(1.lf), d);
    }
    if (bool(fca / 2)) {
        d3_inv = tw;
        tw = dvec3(1.lf);
    }
    else {
        const double d = fma(tF_c.s, -exp2(fma(-.015681467835749602lf, tL_A, -2.5066185556564333lf)), tF_c.s);
        d3_inv = tw / mix(tw, dvec3(1.lf), d);
        tw = mix(tw, dvec3(1.lf), d);
    }
    const dmat3 a = transpose(dmat3(cat16_fwd_T[0] * d3.r, cat16_fwd_T[1] * d3.g, cat16_fwd_T[2] * d3.b)) * smat;
    const dmat3 b = tmat_inv * dmat3(cat16_bwd[0] * d3_inv.r, cat16_bwd[1] * d3_inv.g, cat16_bwd[2] * d3_inv.b);
    double sF_L, tF_L;
    {
        const double k = 1.lf / fma(5.lf, sL_A, 1.lf), k2 = k * k, k4 = k2 * k2, onem_k4 = fma(-k2, k2, 1.lf);
        sF_L = fma(.1709975946676697lf, onem_k4 * onem_k4 * cbrt(sL_A), k4 * sL_A);
    }
    {
        const double k = 1.lf / fma(5.lf, tL_A, 1.lf), k2 = k * k, k4 = k2 * k2, onem_k4 = fma(-k2, k2, 1.lf);
        tF_L = fma(.1709975946676697lf, onem_k4 * onem_k4 * cbrt(tL_A), k4 * tL_A);
    }
    const double c_0 = 27.13lf / pow(sF_L, .42lf);
    sw = cat16_pacr(sw, c_0);
    tw = cat16_pacr(tw, 27.13lf / pow(tF_L, .42lf));
    const double sU = fma(2.lf, sw.r, fma(.05lf, sw.b, sw.g)), tU = fma(2.lf, tw.r, fma(.05lf, tw.b, tw.g));
    const double sL_W = svc.t, tL_W = tvc.t;
    const double sn = sL_A / sL_W, tn = tL_A / tL_W;
    const double c_1 = sF_c.t * (1.48lf + sqrt(sn)) / (tF_c.t * (1.48lf + sqrt(tn)));
    const double c_2 = tU * pow(sU, -c_1);
    const double c_3 = (tF_c.s / sF_c.s) * qirt((sL_A * tL_W) / (sL_W * tL_A)) * pow((1.64lf - pow(.29lf, tn)) / (1.64lf - pow(.29lf, sn)), .81111111111111111lf) * pow(tF_L / sF_L, .277777778);
    const double c_4 = 2588.0680980162957lf / tF_L;
    data[0] = dvec4(a[0], c_0);
    data[1] = dvec4(a[1], c_1);
    data[2] = dvec4(a[2], c_2);
    data[3] = dvec4(b[0], c_3);
    data[4] = dvec4(b[1], c_4);
    data[5] = dvec4(b[2], 0.lf);
}

dmat3 gen_a(const dmat3 fwd, const dvec3 otwht, const dvec3 oswht, const dmat3 bwd, const dmat3 tmat_inv, const dmat3 smat) {
    const dvec3 s = (fwd * otwht) / (fwd * oswht);
    const dmat3 tmp = dmat3(bwd[0] * s.x, bwd[1] * s.y, bwd[2] * s.z);
    return (tmat_inv * tmp) * (fwd * smat);
}

vec4 unpack2xDoubleVec4(const double x, const double y) {
    const uvec4 u = uvec4(unpackDouble2x32(x), unpackDouble2x32(y));
    return uintBitsToFloat(u);
}

void main() {
    const dvec3 swht = gen_wht(sil, spr, sis, sit, sitt, sitd, sixy);
    const dmat3 smat = gen_mat(spr, spx, spy, swht);
    const dvec3 twht = gen_wht(til, tpr, tis, tit, titt, titd, tixy);
    dmat3 tmat, tmat_inv;
    gen_mat(tpr, tpx, tpy, twht, tmat, tmat_inv);
    const dvec3 oswht = gen_owht(osil, swht, osis, osit, ositt, ositd, osixy, osic, smat);
    const dvec3 otwht = gen_owht(otil, twht, otis, otit, otitt, otitd, otixy, otic, tmat);
    dvec4 data[6];
    switch (mtd) {
    case 2:
        gen_bfd(oswht, otwht, smat, tmat_inv, data);
        break;
    case 5:
        gen_cat16(oswht, otwht, smat, tmat_inv, data);
        break;
    default:
        {
            dmat3 a;
            switch (mtd) {
            case 0:
                a = tmat_inv * smat;
                break;
            case 1:
                {
                    const dvec3 s = otwht / oswht;
                    tmat_inv[0] *= s.x;
                    tmat_inv[1] *= s.y;
                    tmat_inv[2] *= s.z;
                    a = tmat_inv * smat;
                }
                break;
            case 3:
                a = gen_a(bfd_fwd, otwht, oswht, bfd_bwd, tmat_inv, smat);
                break;
            case 4:
                {
                    const dmat3 cat02_fwd = dmat3(.7328lf, -.7036lf, .003lf, .4296lf, 1.6975lf, .0136lf, -.1624lf, .0061lf, .9834lf);
                    const dmat3 cat02_bwd = dmat3(1.0961238208355142lf, .45436904197535916lf, -.0096276087384293544lf, -.27886900021828724lf, .47353315430741172lf, -.0056980312161134204lf, .18274517938277308lf, .07209780371722912lf, 1.0153256399545428lf);
                    a = gen_a(cat02_fwd, otwht, oswht, cat02_bwd, tmat_inv, smat);
                }
                break;
            default:
                a = gen_a(cat16_fwd, otwht, oswht, cat16_bwd, tmat_inv, smat);
            }
            data[0].rgb = a[0];
            data[1].rgb = a[1];
            data[2].rgb = a[2];
        }
    }
    const uint x = uint(gl_FragCoord.x);
    const uint y = uint(gl_FragCoord.y);
    if (!adsk_degrade && dbl) {
        if (bool(y))
            fragColor = unpack2xDoubleVec4(data[x].b, data[x].a);
        else
            fragColor = unpack2xDoubleVec4(data[x].r, data[x].g);
        return;
    }
    if (y == 0)
        fragColor = vec4(data[x]);
}
