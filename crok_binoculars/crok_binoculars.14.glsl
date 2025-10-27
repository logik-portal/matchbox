#version 120
// comping it together
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass5, adsk_results_pass13;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	// front with chromatic abberation applied
	vec3 f = texture2D(adsk_results_pass13, uv).rgb;
	// blurred black mask
	float m = texture2D(adsk_results_pass5, uv).r;

	f = f * m;

	gl_FragColor = vec4(f, m);
}
