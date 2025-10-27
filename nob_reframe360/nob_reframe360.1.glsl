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
    float adsk_result_w, adsk_result_h, adsk_result_frameratio;
};

layout (binding = 2) uniform UniformBlock {
    vec3 rot;
    float image_height;
    bool use_fov;
    float f;
    float fov;
    vec2 d_pos;
    float d_ana;
    bool force_par;
    float par;
};

void main() {
    float result_frameratio = force_par ? par * adsk_result_w / adsk_result_h : adsk_result_frameratio;
    float redist_scale;
    {
        float x = (.5 + abs(d_pos.x)) * result_frameratio / d_ana, y = .5 + abs(d_pos.y);
        redist_scale = 1. / (x * x + y * y);
    }
    float h = use_fov ? 2. * tan(.5 * radians(fov)) : image_height / f;
    vec2 cos_psi_sin_psi = vec2(cos(radians(rot.z)), sin(radians(rot.z)));
    vec2 cos_theta_sin_theta = vec2(cos(radians(rot.x)), sin(radians(rot.x)));
    if (gl_FragCoord.x < 1.) {
        fragColor = vec4(result_frameratio, redist_scale, cos_psi_sin_psi);
        return;
    }
    fragColor = vec4(h, cos_theta_sin_theta, 0.);
}
