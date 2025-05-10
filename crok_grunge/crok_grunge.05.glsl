#version 120
// load Blurred Front and Noise
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass3, adsk_results_pass4;
uniform float gain;
uniform int blendmode;

vec3 colorBurn( vec3 s, vec3 d )
{
	return 1.0 - (1.0 - d) / s;
}

vec3 linearBurn( vec3 s, vec3 d )
{
	return s + d - 1.0;
}

vec3 hardMix( vec3 s, vec3 d )
{
	return floor(s + d);
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec3 f = texture2D(adsk_results_pass3, uv).rgb;
	vec3 n = texture2D(adsk_results_pass4, uv).rgb;
	vec3 c = vec3(0.0);

	if ( blendmode == 1 )
		c = c + colorBurn(n, f);
	else if ( blendmode == 2 )
		c = c + linearBurn(n,f);
	else if ( blendmode == 3 )
		c = c + hardMix(n,f);

	//adjust gain
	c = clamp( c * gain, 0.0, 1.0);

	gl_FragColor = vec4(c, 1.0);
}
