#version 120
// load Normals
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D normal;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec3 n = texture2D(normal, uv).rgb;
	gl_FragColor = vec4(n, 1.0);
}
