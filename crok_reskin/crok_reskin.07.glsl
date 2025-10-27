#version 120
// divide and multiply to get a highpass image
// then comp the clean skin with the pimple matte
// after that divide and multiply everything to get back to a healed image;)
uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass4, adsk_results_pass6;
uniform float adsk_result_w, adsk_result_h;
uniform bool en_highpass;

vec2 res = vec2(adsk_result_w, adsk_result_h);

void main( void )
{
	vec2 uv = ( gl_FragCoord.xy / res);
	// load original image
	vec3 o = texture2D(adsk_results_pass1, uv).rgb;
	// get pimple matte
	float m = texture2D(adsk_results_pass1, uv).a;
	// load clean skin image
	vec3 s = texture2D(adsk_results_pass2, uv).rgb;
	//load blurred original image
	vec3 b = texture2D(adsk_results_pass4, uv).rgb;
	//load blurred clean skin
	vec3 bs = texture2D(adsk_results_pass6, uv).rgb;

	// divide org by blurred source
	vec3 c = o / (b + 0.000000001);

	// multiply with gray image to get highpass image
	c = 0.5 * c;
	vec3 high_c = c;

	// divide clean skin by blurred skin
	vec3 cs = s / (bs + 0.000000001);

	// multiply with gray image to get highpass image
	cs = 0.5 * cs;

	//comp clean fg on top of source with pimple matte
	c = vec3(m * cs + (1.0 - m) * c);

	// divide cleaned highpass image by mid gray
	c = c / 0.5;
	// multiply with blurred image to get back to normal image
	c = b * c;

	if ( en_highpass )
		c = high_c;

	gl_FragColor = vec4(c, m);
}
