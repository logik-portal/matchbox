uniform sampler2D adsk_results_pass1, adsk_results_pass4;
uniform float adsk_result_w, adsk_result_h;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );

void main()
{
	vec2 uv = gl_FragCoord.xy/resolution.xy;
  vec4 o = texture2D(adsk_results_pass1, uv);
  vec4 b = texture2D(adsk_results_pass4, uv);

	vec4 c = adsk_getBlendedValue(11, o, b);

  gl_FragColor= c;
}
