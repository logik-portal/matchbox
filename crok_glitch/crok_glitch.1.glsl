#version 120
// based on https://www.shadertoy.com/view/ttBSDR by 104

// --------[ Autodesk Uniforms start here ]---------- //
uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D adsk_results_pass1, adsk_results_pass2;
vec2 res = vec2(adsk_result_w, adsk_result_h);
// --------[ Autodesk Uniforms end here ]---------- //

uniform float complexity;
uniform float density;
uniform float speed;
uniform float offset;

// --------[ Shadertoy Globals start here ]---------- //
#define iTime adsk_time *.05 * speed + offset
#define iResolution res
#define texture texture2D
#define iChannel0 front
#define fragCoord gl_FragCoord
#define fragColor gl_FragColor
// --------[ Shadertoy Globals end here ]---------- //

// --------[ Original ShaderToy starts here ]---------- //

const vec2 z = vec2(1);
//const float complexity =5.;
//const float density = .9;
//const float speed = 1.;


vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

#define q(x,p) (floor((x)/(p))*(p))

void main( void )
{
		vec4 o = vec4(0.0);
		vec2 C = gl_FragCoord.xy;
    vec2 R = iResolution.xy;
    vec2 uv = C/R.xy;
    vec2 N = uv-.5;
    float t = iTime+1e2;
    uv.x *= R.x/R.y;
    uv *= z;
    uv += floor(iTime)*z;
    float s = 1.;

    for (float i = 1.;i <= complexity; ++ i) {
        vec2 c = floor(uv+i);
        vec4 h = hash42(c);
        vec2 p = fract(uv+i+q(t,h.z+1.)*h.y);
        uv+= p*h.z*h.xy*vec2(s,2.);
        uv *= 2.;
        if (i < 2. || h.w > 1.0 - density) {
            o = h;
        }
    }
    o=step(.5,o) * mod(C.x,3.)/2.;
		gl_FragColor = o;
}
