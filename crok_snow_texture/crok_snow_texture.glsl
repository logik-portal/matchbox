#version 120
// based on https://www.shadertoy.com/view/4dGczd by ssell
/*
 * ------------------------------------------------------------------------
 * - Curl Simplex
 * - Created by Steven Sell (ssell) / 2019
 * - License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * - https://www.shadertoy.com/view/4dGczd
 * ------------------------------------------------------------------------
 *
 * An experiment using Simplex Noise as the "backend" of a Curl function.
 *
 * Pieced this together a while ago but decided to make it public because
 * I think the 2D noise result is visually interesting. Curl is also typically
 * used for things like particle motion, so thought it was interesting to
 */

// --------[ Autodesk Uniforms start here ]---------- //
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 res = vec2(adsk_result_w, adsk_result_h);
// --------[ Autodesk Uniforms end here ]---------- //

uniform float smoothness;
uniform float octaves;
uniform float persistence;
uniform float scale;
uniform float p1, p2;
uniform vec2 position;

// --------[ Shadertoy Globals start here ]---------- //
#define iTime adsk_time *.05
#define iResolution res
#define fragCoord gl_FragCoord.xy
#define fragColor gl_FragColor
#define texture texture2D
// --------[ Shadertoy Globals end here ]---------- //

vec4 FetchParameters()
{
    return vec4(smoothness * 20.0 - 10.0,   // Smoothness
                octaves * 9.0 + 1.0,     // Octaves
                persistence,          // Persistence
                scale * 0.01);        // Scale
}

// -------------------------------------------------------------
// Noise
// -------------------------------------------------------------

vec3 hash33s(vec3 p3)
{
	p3 = fract(p3 * vec3(0.1031, 0.11369, 0.13787));
  p3 += dot(p3, p3.yxz + 19.19);
  return -1.0 + 2.0 * fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

float simplex(vec3 pos)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;

    vec3 i = floor(pos + (pos.x + pos.y + pos.z) * K1);
    vec3 d0 = pos - (i - (i.x + i.y + i.z) * K2);

    vec3 e = step(vec3(0.0), d0 - d0.yzx);
	vec3 i1 = e * (1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy * (1.0 - e);

    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);

    vec4 h = max(0.5 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33s(i)), dot(d1, hash33s(i + i1)), dot(d2, hash33s(i + i2)), dot(d3, hash33s(i + 1.0)));

    return dot(vec4(31.316), n);
}

float simplexFbm(vec3 pos, float octaves, float persistence, float scale)
{
    float final        = 0.0;
    float amplitude    = 1.0;
    float maxAmplitude = 0.0;

    for(float i = 0.0; i < octaves; ++i)
    {
        final        += simplex(pos * scale) * amplitude;
        scale        *= 2.0;
        maxAmplitude += amplitude;
        amplitude    *= persistence;
    }

    return final;
}

vec2 curl(float x, float y, float z, float octaves, float persistence, float scale)
{
	float eps = 1.0;
    float n1, n2, a, b;

    n1 = simplexFbm(vec3(x, y + eps, z), octaves, persistence, scale);
    n2 = simplexFbm(vec3(x, y - eps, 0.0), octaves, persistence, scale);
    a  = (n1 - n2) / (2.0 * eps);

    n1 = simplexFbm(vec3(x + eps, y, z), octaves, persistence, scale);
    n2 = simplexFbm(vec3(x - eps, y, z), octaves, persistence, scale);
    b  = (n1 - n2) / (2.0 * eps);

    return vec2(a, -b);
}

void main( void )
{
  vec4 params = FetchParameters();
  vec2 c = curl(fragCoord.x - position.x, fragCoord.y - position.y, params.x, params.y, params.z, params.w);
  c = normalize(c);
  c = (c + 1.0) * 0.5;
  float v = max(c.x, c.y);
  fragColor = vec4(vec3(v), 1.0);
}
