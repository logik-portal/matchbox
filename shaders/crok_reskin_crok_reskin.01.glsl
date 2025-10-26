#version 120
// load the source image
uniform sampler2D source, matte;
uniform float adsk_result_w, adsk_result_h;

vec2 res = vec2(adsk_result_w, adsk_result_h);

void main( void )
{
	vec2 uv = ( gl_FragCoord.xy / res);
  vec3 c = texture2D(source, uv).rgb;
  float m = texture2D(matte, uv).r;

	gl_FragColor = vec4(c, m);
}
