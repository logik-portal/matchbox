uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass4, adsk_results_pass8;

float uv_scale = 2.28;

vec3 spotlight( vec3 s, vec3 d )
{
	vec3 c = 2.0 * d * s;
	return c;
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec3 front = texture2D(adsk_results_pass4, uv).rgb;
  vec3 matte = texture2D(adsk_results_pass4, uv).rgb;
	vec3 p_level = vec3(0.0, 1.0, 1.0);
	vec4 fin_col = vec4(0.0);
	float p_aspect = 1.0;
	float p_scale = 1.0;

// Kodak BW
  matte = min(max(matte - vec3(p_level.x), vec3(0.0)) / (vec3(p_level.z) - vec3(p_level.x)), vec3(1.0));
  matte = pow(matte, vec3(p_level.y));
	matte = clamp(matte, 0.0, 1.0);

	vec2 n_uv = uv / uv_scale;
	vec3 noise = texture2D(adsk_results_pass8, n_uv).rgb;
	vec3 col = spotlight(noise, front);
	vec3 inv_matte = 1.0 - matte;

	fin_col = vec4(inv_matte * col + (matte) * front , matte);
	gl_FragColor = vec4(fin_col.rgb, 1.0);
}
