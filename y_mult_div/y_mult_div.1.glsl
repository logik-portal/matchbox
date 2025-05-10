

#define ratio adsk_result_frameratio

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;
uniform sampler2D Matte;

uniform bool divide;
uniform bool invert;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(Front, st).rgb;
	float matte = texture2D(Matte, st).r;


	if (invert) {
		matte = 1.0 - matte;
	}

	if (divide) {
		front = front / max(matte, .00001);
	} else {
		front *= matte;
	}

	gl_FragColor = vec4(front, matte);
}
