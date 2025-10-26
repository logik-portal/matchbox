#version 120
// adding grain to the edge blur
uniform float adsk_result_w, adsk_result_h, adsk_time, grain_size, high;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform sampler2D adsk_results_pass2, adsk_results_pass4, adsk_results_pass10, adsk_results_pass12, adsk_results_pass8, matte, adsk_results_pass15, adsk_results_pass18, gmask;
uniform bool gmaskInput;
uniform bool show_edge_matte;
uniform int matte_output_sel;

vec3 spotlight( vec3 s, vec3 d )
{
	vec3 c = 2.0 * d * s;
	return c;
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec2 n_uv = (uv-0.5) / grain_size;

	// Gmask Input
	float sel = texture2D(gmask, uv).r;
	sel = gmaskInput ? sel : 1.0;

	float selective_m = texture2D(adsk_results_pass2, uv).r;
	vec3 blured_bg = texture2D(adsk_results_pass4, uv).rgb;
	vec4 normal_comp = texture2D(adsk_results_pass10, uv);
	vec3 blured_comp = texture2D(adsk_results_pass12, uv).rgb;
	vec3 back = texture2D(adsk_results_pass8, uv).rgb;
  vec3 edge_matte = texture2D(adsk_results_pass15, uv).rgb;
	vec3 grain = texture2D(adsk_results_pass18, n_uv).rgb;
	vec3 mask = texture2D(matte, uv).rgb;

	float matte_out = 1.0;

  //levels input range
  vec3 g_matte = min(max(normal_comp.rgb - vec3(0.0), vec3(0.0)) / (vec3(1.0 - high) - vec3(0.0)), vec3(1.0));
	vec3 inv_matte = 1.0 - g_matte;
  vec3 comp = mix(normal_comp.rgb, blured_comp, edge_matte * sel);
	vec3 grain_c = spotlight(grain, comp);
	grain_c = vec3(inv_matte * grain_c + (g_matte) * comp);

	comp = mix(comp, grain_c, edge_matte  * sel);

	if ( show_edge_matte )
		comp = vec3(edge_matte);

	if ( matte_output_sel == 0 )
		normal_comp.a = mask.r;
	else if ( matte_output_sel == 1 )
		normal_comp.a = edge_matte.r * sel * selective_m;
	else if ( matte_output_sel == 2 )
		normal_comp.a = normal_comp.a * sel * selective_m;

	gl_FragColor = vec4(comp, normal_comp.a);
}
