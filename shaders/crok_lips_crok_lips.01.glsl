#version 120
// load Front and matte
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front, matte;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec3 f = texture2D(front, uv).rgb;
	float m = texture2D(matte, uv).r;
	gl_FragColor = vec4(f, m);
}
