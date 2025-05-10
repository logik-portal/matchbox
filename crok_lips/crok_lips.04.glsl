#version 120
// divide source with dollface
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, adsk_results_pass3;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec3 o = texture2D(adsk_results_pass1, uv).rgb;
	vec3 d = texture2D(adsk_results_pass3, uv).rgb;

	// divide source by dollface
	vec3 c = o / d;
	
	gl_FragColor = vec4(c, 1.0);
}
