#version 120
// auto scale
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec4 c = texture2D(adsk_results_pass1, uv);
	gl_FragColor = vec4(c);
}
