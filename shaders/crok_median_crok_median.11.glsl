#version 120
// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
uniform sampler2D adsk_results_pass1, adsk_results_pass10, matte;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main()
{
	vec2 uv = gl_FragCoord.xy / res;
	vec4 o = texture2D(adsk_results_pass1, uv);
	vec4 c = texture2D(adsk_results_pass10, uv);
	vec4 m = texture2D(matte, uv);
	c = vec4(m * c + (1.0 - m) * o);
  gl_FragColor = vec4(c.rgb, m);
}
