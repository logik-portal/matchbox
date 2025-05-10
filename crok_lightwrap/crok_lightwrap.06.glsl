#version 120
// comp lightwrap
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform sampler2D adsk_results_pass2, adsk_results_pass4, adsk_results_pass5, compo, matte;

uniform float blend, lm_threshold, gain, sat, bias_adj;
uniform int LogicOp;
uniform int result;

uniform bool relight;

#define luma(col) dot(col, vec3(0.3086, 0.6094, 0.0820))

vec3 normal( vec3 s, vec3 d )
{
	return s;
}

vec3 multiply( vec3 s, vec3 d )
{
	return s*d;
}

vec3 screen( vec3 s, vec3 d )
{
	return s + d - s * d;
}

vec3 linearDodge( vec3 s, vec3 d )
{
	return s + d;
}

vec3 lighten( vec3 s, vec3 d )
{
	return max(s,d);
}

vec3 lighterColor( vec3 s, vec3 d )
{
	return (s.x + s.y + s.z > d.x + d.y + d.z) ? s : d;
}

float overlay( float s, float d )
{
	return (d < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}
vec3 overlay( vec3 s, vec3 d )
{
	vec3 c;
	c.x = overlay(s.x,d.x);
	c.y = overlay(s.y,d.y);
	c.z = overlay(s.z,d.z);
	return c;
}

vec3 spotlightBlend (vec3 s, vec3 d)
{
	return ( s * d + s);
}

vec3 adjust_saturation(vec3 col, float c)
{
    float l = luma(col);
    col = (1.0 - c) * l + c * col;

    return col;
}

float bias ( float x, float b )
{
    b = -log2(1.0 - b);
    return 1.0 - pow(abs(1.0 - pow(abs(x), 1./b)), b);
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec3 lightwrap_matte = vec3(0.0);
	vec3 comp = vec3(0.0);
	vec3 black = vec3(0.0);
	vec3 front = texture2D(compo, uv).rgb;
	vec3 back = texture2D(adsk_results_pass2, uv).rgb;
	vec3 bg_histo = back;
    vec3 alpha = texture2D(matte, uv).rgb;
	vec3 blurred_matte = texture2D(adsk_results_pass4, uv).rgb;
	vec3 relight_matte = texture2D(adsk_results_pass5, uv).rgb;
	vec3 inv_matte = 1.0 - blurred_matte;

  bg_histo = pow(abs(back), vec3(lm_threshold));
	bg_histo = vec3(max(max(bg_histo.r, bg_histo.g), bg_histo.b));
	bg_histo = bg_histo * gain;


	lightwrap_matte = multiply(alpha, inv_matte);
	lightwrap_matte = multiply(bg_histo, lightwrap_matte);

	if ( relight )
	{
		lightwrap_matte = multiply(lightwrap_matte, relight_matte);
		lightwrap_matte = multiply(lightwrap_matte, alpha);
		lightwrap_matte = lightwrap_matte * gain * 5.0;
	}

	// bias adjustement
	//lightwrap_matte = vec3(bias(lightwrap_matte.r, bias_adj));

	back = adjust_saturation(back, sat);

    if( LogicOp ==0)
		comp = screen(back, front);
    else if ( LogicOp == 1)
		comp = linearDodge(back, front);
	else if ( LogicOp == 2)
		comp = lighten(back, front);
    else if ( LogicOp == 3)
		comp = lighterColor(back, front);
    else if ( LogicOp == 4)
		comp = overlay(back, front);
    else if ( LogicOp == 5)
		comp = spotlightBlend(front, back);
    else
		comp = normal(back, front);

	if ( result == 1)
		comp = mix(black, comp, lightwrap_matte * blend);
	else
		comp = mix(front, comp, lightwrap_matte * blend);

	gl_FragColor = vec4(comp, lightwrap_matte );
}
