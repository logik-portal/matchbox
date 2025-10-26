#version 120

uniform sampler2D adsk_results_pass4;
uniform float adsk_result_w, adsk_result_h, adsk_time;
float time = adsk_time *.05 + 5.0;
uniform float offset;

vec3 lighten( vec3 s, vec3 d )
{
	return max(s,d);
}

//https://www.shadertoy.com/view/4sXSWs strength= 16.0
vec3 filmGrain(vec2 uv, float strength )
{
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (time * 10.0);
	return  vec3(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec2 center = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h) - 0.5;

	vec3 c = texture2D(adsk_results_pass4, uv).rgb;

	// filmgrain
	c -= filmGrain(uv, 5.);

	// vignette
	vec3 tint_col = vec3(0.0);
  float length = length(center);
  float vig = smoothstep(1., .3, length);
	vec3 matte = vec3(1.0-vig);
	c = matte * vec3(0.0) + (1.0 - matte) * c;

	gl_FragColor.rgb = c;
}
