#version 120

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform sampler2D adsk_results_pass1, adsk_results_pass3, adsk_results_pass5;
uniform float gain, minInput;

void main()
{
	vec2 uv = gl_FragCoord.xy / res.xy;
	vec3 org = texture2D(adsk_results_pass1, uv).rgb;
	vec3 mat = texture2D(adsk_results_pass3, uv).rgb;
	vec3 col = texture2D(adsk_results_pass5, uv).rgb;

	mat = min(max(mat - vec3(minInput), vec3(0.0)) / (vec3(1.0) - vec3(minInput)), vec3(1.0));
  mat = mix(vec3(0.0), vec3(1.0), mat);

	mat *= gain;
	mat = clamp(mat, 0.0, 1.0);

	col = vec3(mat * col + (1.0 - mat) * org);

  gl_FragColor = vec4(col, mat);
}
