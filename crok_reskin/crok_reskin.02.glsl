#version 120
// load the clean skin
uniform sampler2D clean;
uniform float adsk_result_w, adsk_result_h;

vec2 res = vec2(adsk_result_w, adsk_result_h);

void main( void )
{
	vec2 uv = ( gl_FragCoord.xy / res);
  vec3 c = texture2D(clean, uv).rgb;

	gl_FragColor = vec4(c, 1.0);
}
