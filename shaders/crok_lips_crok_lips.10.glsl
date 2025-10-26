#version 120
// load result of pixelspread, dollface and matte
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, adsk_results_pass3, adsk_results_pass4, adsk_results_pass8, adsk_results_pass9;
uniform float blend;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec4 o = texture2D(adsk_results_pass1, uv);
	vec3 c_doll = texture2D(adsk_results_pass3, uv).rgb;
	vec3 c_div = texture2D(adsk_results_pass4, uv).rgb;
	vec3 c_pixel = texture2D(adsk_results_pass9, uv).rgb;
	float m = texture2D(adsk_results_pass8, uv).r;

	// comp pixelspread with dollface via matte
	//vec3 c = vec3(o.a * c_pixel + (1.0 - o.a) * c_doll);
	vec3 c = vec3(m * c_pixel + (1.0 - m) * c_doll);

	// multiply the result with the dollface divide
	c = c * c_div;

	// blend the source footage with the result
	c = mix( o.rgb, c, blend );

	gl_FragColor = vec4( c, m );
}
