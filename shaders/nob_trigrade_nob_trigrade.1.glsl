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

dvec3 lum = dvec3(w_r, 1.lf - double(w_r + w_b), w_b);

void process_input(uint mode, bool norm, vec3 src, vec3 tar_c, vec3 tar_o, vec3 tar_g, inout uint n, inout dmat3 x, inout dmat3 y) {
    if (mode == 0)
        return;
    dvec3 tar;
    if (mode == 1)
        tar = tar_c;
    dvec3 dsrc = src;
    if (mode == 2)
        tar = dsrc + dvec3(tar_o) / 100.lf;
    if (mode == 3)
        tar = dsrc * dvec3(tar_g) / 10.lf;
    double src_len = length(dsrc);
    dsrc /= src_len;
    if (norm)
        tar *= dot(lum, dsrc) / dot(lum, tar);
    else
        tar /= src_len;
    x[n] = dsrc;
    y[n] = tar;
    ++n;
}

void main() {
    uint n = 0;
    dmat3 x, y;
    process_input(vec_1_mode, vec_1_norm, vec_1_src, vec_1_tar_c, vec_1_tar_o, vec_1_tar_g, n, x, y);
    process_input(vec_2_mode, vec_2_norm, vec_2_src, vec_2_tar_c, vec_2_tar_o, vec_2_tar_g, n, x, y);
    process_input(vec_3_mode, vec_3_norm, vec_3_src, vec_3_tar_c, vec_3_tar_o, vec_3_tar_g, n, x, y);
    switch (n) {
    case 0:
        if (gl_FragCoord.x < 1.) {
            fragColor = vec4(1., 0., 0., 0.);
            return;
        }
        if (gl_FragCoord.x < 2.) {
            fragColor = vec4(0., 1., 0., 0.);
            return;
        }
        fragColor = vec4(0., 0., 1., 0.);
        return;
    case 1:
        y = dmat3(1.lf) + outerProduct(y[0] - x[0], x[0]);
        break;
    case 2:
        double c = dot(x[0], x[1]);
        dmat2 g_inv = 1.lf / (1.lf - c * c) * dmat2(1.lf, -c, -c, 1.lf);
        y = dmat3(1.lf) + (dmat2x3(y) - dmat2x3(x)) * (g_inv * transpose(dmat2x3(x)));
        break;
    case 3:
        dmat3 b = inverse(x);
        y = y * b;
    }
    if (gl_FragCoord.x < 1.) {
        fragColor = vec4(y[0], 0.);
        return;
    }
    if (gl_FragCoord.x < 2.) {
        fragColor = vec4(y[1], 0.);
        return;
    }
    fragColor = vec4(y[2], 0.);
}
