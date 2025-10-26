#version 120

uniform sampler2D source;
uniform float adsk_result_w, adsk_result_h;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	
	// source
	vec3 scr = texture2D(source, uv).rgb;

	gl_FragColor = vec4(scr, 1.0);

}