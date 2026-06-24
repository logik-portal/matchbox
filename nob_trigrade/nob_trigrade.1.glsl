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
    bool perceptual;
    uint working_cs;
    bool perceptual_controls;
    float post_saturation;
    bool double_precision;
    uint vec_1_mode;
    uint vec_2_mode;
    uint vec_3_mode;
    float w_r;
    bool vec_1_norm;
    bool vec_2_norm;
    bool vec_3_norm;
    float w_b;
    vec3 vec_1_tar_c;
    vec3 vec_1_tar_o;
    vec3 vec_1_tar_g;
    vec3 vec_1_src;
    vec3 vec_2_tar_c;
    vec3 vec_2_tar_o;
    vec3 vec_2_tar_g;
    vec3 vec_2_src;
    vec3 vec_3_tar_c;
    vec3 vec_3_tar_o;
    vec3 vec_3_tar_g;
    vec3 vec_3_src;
};

const dmat3 to_lms[] = {
    dmat3(.6316940125690677lf, .2700701631304252lf, .09879026885552336lf, .3488616031689251lf, .6309514529951127lf, .1853215485517749lf, .01933519000413487lf, .0990052983225776lf, .7163678285649206lf),
    dmat3(.8903196478109062lf, .3445120810846759lf, .1351584376260158lf, .26082231749493lf, .6776720976791309lf, .1902942961951732lf, -.1512511595637086lf, -.02215726431569132lf, .6750269121510299lf),
    dmat3(.4121764591770372lf, .2119091995880486lf, .08834481407213209lf, .536273974269589lf, .6807178709823129lf, .2818539630985774lf, .05144037229550144lf, .1073998438777539lf, .6302808688015094lf),
    dmat3(.6166884417511042lf, .2651401961832022lf, .1001506451032589lf, .3601590704701178lf, .6358564846985175lf, .2040043234319268lf, .02304329352090565lf, .09903023356639583lf, .6963246774370332lf),
    dmat3(.4813272911960764lf, .2288381013317354lf, .08398601779387474lf, .4620679116724793lf, .6532343999261816lf, .2242727892997343lf, .05649560287357199lf, .1179544131901985lf, .6922208388786098lf),
    dmat3(.6693355806024931lf, .2597817687173177lf, .1012619906815526lf, .3890557905100418lf, .7305166184357663lf, .2128508379706724lf, -.0585005653704073lf, .009728527295031519lf, .6863668173199939lf),
    dmat3(.7161538826377626lf, .2878008330968424lf, .06072689106893754lf, .4059911717907131lf, .7730986243381548lf, .005998151880339111lf, -.122254248686348lf, -.06087254298688172lf, .9337546030229422lf),
    dmat3(.8189330101lf, .0329845436lf, .0482003018lf, .3618667424lf, .9293118715lf, .2643662691lf, -.1288597137lf, .0361456387lf, .633851707lf),
    dmat3(.5590606388069453lf, .2169905870294775lf, .08458107583067195lf, .4182290963299687lf, .6718397543963339lf, .2104808849823149lf, .02260107060521365lf, .1111965730223041lf, .705417685159232lf)
};

const dmat3 lms_to_lab = dmat3(.2104542553lf, 1.9779984951lf, .0259040371lf, .793617785lf, -2.428592205lf, .7827717662lf, -.0040720468lf, .4505937099lf, -.808675766lf);
const dmat3 lms_to_labT1 = dmat3(3.95744005932982lf, -4.616454537894103lf, .8694687334625503lf, -4.616454537894103lf, 7.140620924814936lf, -1.730548577881962lf, .8694687334625503lf, -1.730548577881962lf, .8570077674822735lf);

dvec3 cbrt(dvec3 x) {
    const double scale[] = {
        .6299605249474366lf,
        .7937005259840997lf,
        1.lf,
        1.259921049894873lf,
        1.587401051968199lf
    };
    dvec3 s = sign(x);
    x = abs(x);
    ivec3 e;
    dvec3 m = frexp(x, e);
    dvec3 y = .4943965824016093lf + (.6944362432644339lf - .1893976029726157lf * m) * m;
    dvec3 t = y * y * y;
    y *= (t + 2.lf * m) / (2.lf * t + m);
    ivec3 e_3 = e / 3;
    e -= 3 * e_3;
    y *= dvec3(scale[e.r + 2], scale[e.g + 2], scale[e.b + 2]);
    y = ldexp(y, e_3);
    y = (2.lf * y + x / (y * y)) / 3.lf;
    return s * y;
}

void process_input(uint mode, bool norm, vec3 src, vec3 tar_c, vec3 tar_o, vec3 tar_g, inout uint n, inout dmat3 x, inout dmat3 y, inout bvec3 normv) {
    if (mode == 0)
        return;
    dvec3 dsrc = src;
    dvec3 tar;
    if (mode == 1) {
        tar = tar_c;
        if (perceptual) {
            dsrc = to_lms[working_cs] * dsrc;
            tar = to_lms[working_cs] * tar;
            dsrc = cbrt(dsrc);
            tar = cbrt(tar);
        }
    }
    if (mode == 2) {
        tar = tar_o;
        if (!perceptual || !perceptual_controls)
            tar = dsrc + tar / 100.lf;
        if (perceptual) {
            dsrc = to_lms[working_cs] * dsrc;
            dsrc = cbrt(dsrc);
            if (perceptual_controls) {
                const dmat3 c_m = dmat3(.01321772862049234lf, .009125980007268683lf, .005959477898453426lf, .007933224724842103lf, .0105334645715841lf, .007152600326386303lf, .008849046608181151lf, .01034055568760004lf, .0168879234153326lf);
                tar = dsrc + c_m * tar;
            }
            else {
                tar = to_lms[working_cs] * tar;
                tar = cbrt(tar);
            }
        }
    }
    if (mode == 3) {
        tar = tar_g;
        if (!perceptual || !perceptual_controls)
            tar = dsrc * tar / 10.lf;
        if (perceptual) {
            dsrc = to_lms[working_cs] * dsrc;
            dsrc = cbrt(dsrc);
            if (perceptual_controls) {
                const dmat3 c_m = dmat3(.03333333333333333lf, .06666666666666667lf, .02666666666666667lf, .03333333333333333lf, -.06666666666666667lf, .02666666666666667lf, .03333333333333333lf, 0.lf, -.05333333333333333lf);
                const dmat3 lab_to_lms = dmat3(.9999999984505198lf, 1.000000008881761lf, 1.000000054672411lf, .3963377921737679lf, -.1055613423236563lf, -.08948418209496576lf, .2158037580607588lf, -.0638541747717059lf, -1.291485537864092lf);
                tar = lab_to_lms * ((lms_to_lab * dsrc) * (c_m * tar + dvec3(0.lf, 1.lf, 1.lf)));
            }
            else {
                tar = to_lms[working_cs] * tar;
                tar = cbrt(tar);
            }
        }
    }
    x[n] = dsrc;
    y[n] = tar;
    normv[n] = norm;
    ++n;
}

vec4 unpack2xDoubleVec4(double x, double y) {
    uvec4 u = uvec4(unpackDouble2x32(x), unpackDouble2x32(y));
    return uintBitsToFloat(u);
}

vec2 unpackDoubleVec2(double x) {
    uvec2 u = unpackDouble2x32(x);
    return uintBitsToFloat(u);
}

void main() {
    dvec3 lum;
    uint n = 0;
    dmat3 x, y;
    bvec3 normv;
    if (perceptual)
        lum = dvec3(.2104542553lf, .793617785lf, -.0040720468lf);
    else
        lum = dvec3(w_r, 1.lf - (double(w_r) + double(w_b)), w_b);
    process_input(vec_1_mode, vec_1_norm, vec_1_src, vec_1_tar_c, vec_1_tar_o, vec_1_tar_g, n, x, y, normv);
    process_input(vec_2_mode, vec_2_norm, vec_2_src, vec_2_tar_c, vec_2_tar_o, vec_2_tar_g, n, x, y, normv);
    process_input(vec_3_mode, vec_3_norm, vec_3_src, vec_3_tar_c, vec_3_tar_o, vec_3_tar_g, n, x, y, normv);
    switch (n) {
    case 0:
        y = dmat3(1.lf);
        break;
    case 1:
        if (normv.r)
            y[0] *= dot(lum, x[0]) / dot(lum, y[0]);
        if (perceptual) {
            dvec3 t = lms_to_lab * x[0];
            y = dmat3(1.lf) + outerProduct(y[0] - x[0], lms_to_labT1 * x[0]) / dot(t, t);
        }
        else
            y = dmat3(1.lf) + outerProduct(y[0] - x[0], x[0]) / dot(x[0], x[0]);
        break;
    case 2:
        for (uint i = 0; i < 2; ++i) {
            if (normv[i])
                y[i] *= dot(lum, x[i]) / dot(lum, y[i]);
        }
        if (perceptual) {
            dmat2x3 t = lms_to_lab * dmat2x3(x);
            double a = dot(t[0], t[0]), b = dot(t[1], t[1]), c = dot(t[0], t[1]);
            dmat2 g = dmat2(b, -c, -c, a);
            y = dmat3(1.lf) + (dmat2x3(y) - dmat2x3(x)) * (g * transpose(lms_to_labT1 * dmat2x3(x))) / (a * b - c * c);
        }
        else {
            double a = dot(x[0], x[0]), b = dot(x[1], x[1]), c = dot(x[0], x[1]);
            dmat2 g = dmat2(b, -c, -c, a);
            y = dmat3(1.lf) + (dmat2x3(y) - dmat2x3(x)) * (g * transpose(dmat2x3(x))) / (a * b - c * c);
        }
        break;
    default:
        for (uint i = 0; i < 3; ++i) {
            double len = length(x[i]);
            x[i] /= len;
            if (normv[i])
                y[i] *= dot(lum, x[i]) / dot(lum, y[i]);
            else
                y[i] /= len;
        }
        y = y * inverse(x);
    }
    {
        dmat3 s;
        if (perceptual) {
            dmat3 s_0 = dmat3(.2104542549739053lf, .2104542571692044lf, .2104542668060415lf, .7936177837703050lf, .7936177920487233lf, .7936178283889977lf, -.004072046793690444lf, -.004072046836166946lf, -.004072047022628616lf);
            dmat3 s_1 = dmat3(.7895457450260947lf, -.2104542571692044lf, -.2104542668060415lf, -.7936177837703050lf, .2063822079512767lf, -.7936178283889977lf, .004072046793690444lf, .004072046836166946lf, 1.004072047022629lf);
            s = s_0 + double(post_saturation) * s_1;
        }
        else {
            double ps = post_saturation;
            double ps_i = 1.lf - ps;
            double c_0 = w_r, c_1_i = double(w_r) + double(w_b), c_2 = w_b;
            double c_0_i = 1.lf - c_0, c_1 = 1.lf - c_1_i, c_2_i = 1.lf - c_2;
            s = dmat3(ps * c_0_i + c_0, ps_i * c_0, ps_i * c_0, ps_i * c_1, ps * c_1_i + c_1, ps_i * c_1, ps_i * c_2, ps_i * c_2, ps * c_2_i + c_2);
        }
        y = s * y;
    }
    if (double_precision) {
        if (gl_FragCoord.x < 1.) {
            fragColor = unpack2xDoubleVec4(y[0].r, y[0].g);
            return;
        }
        if (gl_FragCoord.x < 2.) {
            fragColor = unpack2xDoubleVec4(y[0].b, y[1].r);
            return;
        }
        if (gl_FragCoord.x < 3.) {
            fragColor = unpack2xDoubleVec4(y[1].g, y[1].b);
            return;
        }
        if (gl_FragCoord.x < 4.) {
            fragColor = unpack2xDoubleVec4(y[2].r, y[2].g);
            return;
        }
        fragColor = vec4(unpackDoubleVec2(y[2].b), 0., 0.);
        return;
    }
    if (gl_FragCoord.x < 1.) {
        fragColor = vec4(y[0], 0.);
        return;
    }
    if (gl_FragCoord.x < 2.) {
        fragColor = vec4(y[1], 0.);
        return;
    }
    if (gl_FragCoord.x < 3.)
        fragColor = vec4(y[2], 0.);
}
