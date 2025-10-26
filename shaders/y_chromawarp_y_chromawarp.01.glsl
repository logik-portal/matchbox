#version 120
#extension GL_ARB_shader_texture_lod : enable

#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969

float   adsk_getLuminance( vec3 rgb );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Matte;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	float matte = texture2D(Matte, st).r;

	gl_FragColor = vec4(matte);
}
