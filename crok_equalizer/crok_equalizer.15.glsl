#version 120
#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D source, matte, adsk_results_pass12, adsk_results_pass14;
uniform float adsk_result_w, adsk_result_h;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
uniform float blend_05;
uniform float blend_overall;

vec3 linearLight( vec3 s, vec3 d )
{
	return 2.0 * s + d - 1.0;
}

vec3 subtract( vec3 s, vec3 d )
{
	return s - d;
}

vec3 linearDodge( vec3 s, vec3 d )
{
	return s + d;
}


void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);

	// original
	vec3 org = texture2D(source, uv).rgb;

	// matte
	vec3 matte = texture2D(matte, uv).rgb;

	// source
	vec3 scr = texture2D(adsk_results_pass12, uv).rgb;
	// blured source
	vec3 b_scr = texture2D(adsk_results_pass14, uv).rgb;

	vec3 c = vec3(0.0);
	vec3 fifty_p_grey = vec3(0.5);

	// suptract operation
	vec3 sub =  c + subtract(scr, b_scr);

	// linear dodge operation
	c =  c + linearDodge(sub, fifty_p_grey);

	// adjust contrast to 50%
	c = c * 0.5 + 0.25;

	//invert the higpass
	c = 1.0 - c;
	// merge highpass ontop of the blured painted one
	c =  linearLight(c, scr);

	//blend original to highpass
	c = mix(scr, c, blend_05);

	c = mix(org, c, blend_overall);

	c = vec3(matte * c + (1.0 - matte) * org);

	gl_FragColor = vec4(c, matte);
}
